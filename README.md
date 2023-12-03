# cloud-deployment
*(Примечание: в коммите до этого из кода лишь были удалены компрометирующие меня данные - не более)*

Для развертывания отказоустойчивой инсталляции для меня принципиально было использовать IaC-инструменты, такие как terraform и ansible (первый создает сервера, второй эти сервера накатывает),  YAML-спецификации и cloud init избегались мною осознанно. Избегались также готовые решения вроде Managed Service for PostgreSQL или COI. Использовался только образ Ubuntu 22.04 LTS.

Ansible playbooks вызываюся непостредственно terraform с помошью remote-exec, который ожидает соединения с сервером, а затем запускает local-exec *(хотя, очевидно, вариант с динамическим inventory куда более изящнее)*. Переменные для ansible (./vars/main.yaml) формируются динамически (см. ansible-vars.tf).

Одним из важнейших требований, предъявляемых к создаваемой инфраструктуре была отказоустойчивость. Yandex cloud предоставляет два важнейших инструмента ее обеспечения - Instance group и (L-3, L-7) load balancer:

1) Load Balancer за счет механизма проверки состояния присваивает каждой ВМ из целевой группы статус healthy или unhealthy и исходя из этого распределять получаемый траффик. Ключевым является параметр max_opening_traffic_duration - время по истечении которого Compute Cloud автоматически восстановит ВМ, которая не получает трафик слишком долго с момента добавления в группу или запуска.

2) Instance Group также имеет механизм проверки статуса ВМ и может предпринимать действия, исходя из политики восстановления и политики развертывания (параметры max_unavailable и max_expansion)

*(Вы, наверное, уже заметили, что мой стенд не прошел первые две проверки отказоустойчивости. Скорее всего это произошло из-за неправильно настроенных интервалов проверок - примечание в документации о том, что при интеграции с Network Load Balancer проверки в Instance Groups выставляйте более мягкие настройки, чем для проверки состояния в балансировщике - были мною успешно проигнорированы. В этом плане урок усвоен)*

Следующей задачей после обнаружения пути к config.yaml и main.log файлам (с помощью отслеживания системных вызовов утилитой strace) - из-за склонности bingo умирать, стал поиск способов восстановления bingo-приложения. Восстановление приложения было обеспечено с помощью его демонизации, т.е. написанием unit-файла:
<details>
<summary> bingo.service</summary>
<pre>[Unit]
Description=Start bingo binary
After=network.target

[Service]
OOMScoreAdjust=-500
User=ubuntu
Group=root
WorkingDirectory=/bin/
ExecStart=/bin/bingo run_server localhost
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
PrivateTmp=true
Restart=always

[Install]
WantedBy=default.target</pre>
</details>


Из-за отсутствия опыта работы с базами данными (с postgresql в частности), настройка postgresql-кастера стал самым слабым местом моего стенда *(однако теперь необходимость в создании индексов для корректного ответа на GET запросы мне понятна)*. Для управления репликами мною был использован инструмент repmgr. Для развертывания кластера и настройки репликации были написаны две ansible-роли: registration и repmgr.

<details>
<summary>  repmgr</summary>
<pre>- name: Download repmgr repository installer
  get_url:
    dest: /tmp/repmgr-installer.sh
    mode: 0700
    url: https://dl.2ndquadrant.com/default/release/get/deb


- name: Execute repmgr repository installer
  shell: /tmp/repmgr-installer.sh


- name: Install repmgr for PostgreSQL {{ pg_version }}
  apt:
    name: postgresql-{{ pg_version }}-repmgr
    update_cache: yes

 
- name: Setup repmgr user and database
  become_user: postgres
  ignore_errors: yes
  shell: |
    createuser --replication --createdb --createrole --superuser repmgr &&
    psql -c 'ALTER USER repmgr SET search_path TO repmgr_test, "$user", public;' &&
    createdb repmgr --owner=repmgr


- name: Copy repmgr configuration
  template:
    src: repmgr.conf.j2
    dest: /etc/repmgr.conf


- name: Restart PostgreSQL
  systemd:
    name: postgresql
    enabled: yes
	state: restarted</pre>
</details>


<details>
<summary>registration</summary>
<pre>- name: Register primary node
  become_user: postgres
  shell: repmgr primary register
  ignore_errors: yes
  when: ansible_hostname == "db01"

- name: Stop PostgreSQL
  systemd:
    name: postgresql
    state: stopped
  when: ansible_hostname == "db02"

- name: Clean up PostgreSQL data directory
  become_user: postgres
  file:
    path: /var/lib/postgresql/{{ pg_version }}/main
    force: yes
    state: absent
  when: ansible_hostname == "db02"

- name: Clone primary node data
  become_user: postgres
  shell: repmgr -h {{ db01_ip }} -U repmgr -d repmgr standby clone
  ignore_errors: yes
  when: ansible_hostname == "db02"

- name: Start PostgreSQL
  systemd:
    name: postgresql
    state: started
  when: ansible_hostname == "db02"

- name: Register {{ role }} node
  become_user: postgres
  shell: repmgr -h {{ db01_ip }} primary register -F
  ignore_errors: yes
  when: ansible_hostname != "db01"

- name: Start repmgrd
  become_user: postgres
  shell: repmgrd
  ignore_errors: yes</pre>
</details>

Также на каждой ноде с bingo развернут nginx для reverse-проксирования и кэширование /long_dummy *(которое в последнем тестировании, по непонятной мне причине, Петя не заметил, не смотря на то, что в попытках до этого всегда замечал)*. Стандартный конфигурационный файл nginx был отредактирован для улучшения показателей RPS. Также для этих целей были внесены правки в файл /etc/security/limits.conf для увеличения лимита открытых файлов (в том числе сокетов).
