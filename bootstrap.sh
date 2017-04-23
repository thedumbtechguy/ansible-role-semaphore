

# init
if [ "$1" = "init" ]; then

    
    echo "Enter the database root password (admin):"
    read semaphore_db_admin_password

    echo "Enter the database password for the application (semaphore):"
    read semaphore_db_auth_password

    echo "Enter the password for the default application user (semaphore<root@localhost>):"
    read semaphore_config_auth_password

    echo "Enter the password for the account that will execute the application service (semaphore):"
    read semaphore_service_user_password

    echo "Enter your ansible vault password (/var/lib/semaphore/.vpf):"
    read semaphore_ansible_cfg_vault_password

    cat > vars.json <<EOL
{
    "semaphore_version": "2.3.0",
    "semaphore_port": 3000,

    "semaphore_service_user_name": "semaphore",
    "semaphore_service_user_password": "$semaphore_service_user_password", # required
    
    "semaphore_db_admin_home": "/root",
    "semaphore_db_admin_user": "admin",
    "semaphore_db_admin_password": "$semaphore_db_admin_password", # required
    
    "semaphore_db_name": "semaphore",
    "semaphore_db_auth_user": "semaphore",
    "semaphore_db_auth_password": "$semaphore_db_auth_password", # required
    semaphore_db_auth_privileges: "*.*:ALL",

    "semaphore_config_data_dir": "/var/lib/semaphore",
    "semaphore_config_log_path": "/var/log/semaphore",

    "semaphore_config_auth_name": "Admin",
    "semaphore_config_auth_email": "root@localhost",
    "semaphore_config_auth_username": "admin",
    "semaphore_config_auth_password": "$semaphore_config_auth_password", # required
        
    "semaphore_config_email_alerts_enable": "no",
    "semaphore_config_email_alerts_server": "localhost",
    "semaphore_config_email_alerts_port": 25,
    "semaphore_config_email_alerts_sender": "semaphore@localhost",
    "semaphore_config_telegram_alerts_enable": "no",
    "semaphore_config_telegram_alerts_bot_token": "",
    "semaphore_config_telegram_alerts_chat_id": "",
    "semaphore_config_web_root": "http://$HOSTNAME:3000/", # used in generating urls in alerts
    
    "semaphore_config_ldap_enable": "no",
    "semaphore_config_ldap_server": "localhost",
    "semaphore_config_ldap_port": 389,
    "semaphore_config_ldap_use_tls": "no",
    "semaphore_config_ldap_bind_dn": "cn=user,ou=users,dc=example.tld",
    "semaphore_config_ldap_bind_password": "pa55w0rd",
    "semaphore_config_ldap_search_dn": "ou=users,dc=example.tld",
    "semaphore_config_ldap_search_filter": "(uid=%s)",
    "semaphore_config_ldap_mapping_dn_field": "dn",
    "semaphore_config_ldap_mapping_username_field": "uid",
    "semaphore_config_ldap_mapping_fullname_field": "cn",
    "semaphore_config_ldap_mapping_email_field": "mail",

    "semaphore_ansible_cfg_host_key_checking": "False",
    "semaphore_ansible_cfg_ansible_managed": "DO NOT MODIFY by hand. This file is under control of Ansible on {host}.",
    "semaphore_ansible_cfg_vault_password": "$semaphore_ansible_cfg_vault_password",
    "semaphore_ansible_cfg_vault_password_file": "/var/lib/semaphore/.vpf",
}
EOL

    cat > playbook.yml <<EOL
---


- hosts: 127.0.0.1
  connection: local
  become: yes

  vars:
    mariadb_group_users:
      - name: '{{ semaphore_db_auth_user }}'
        password: '{{ semaphore_db_auth_password }}'
        priv: '*.*:ALL'
        hosts:
          - localhost
          - 127.0.0.1

    mariadb_admin_home: '{{ semaphore_db_admin_home }}'
    mariadb_admin_user: '{{ semaphore_db_admin_user }}'
    mariadb_admin_password: '{{ semaphore_db_admin_password }}'

    logrotate_conf_scripts:
      - name: semaphore
        path: /var/log/semaphore/*.log
        options:
          - rotate 14
          - daily
          - compress
          - delaycompress
          - sharedscripts
          - missingok
        postrotate:
          - /usr/sbin/service semaphore restart
    
    configure_self_vault_password: '{{ semaphore_ansible_cfg_vault_password}}'
    configure_self_vault_password_file: '{{ semaphore_ansible_cfg_vault_password_file }}'
    configure_self_vault_password_file_owner: root
    configure_self_vault_password_file_group: '{{ semaphore_service_user_name }}'
    configure_self_vault_password_file_permissions: 0640
    configure_self_config_defaults:
      - name: host_key_checking
        value: '{{ semaphore_ansible_cfg_host_key_checking }}'
      - name: ansible_managed
        value: 'DO NOT MODIFY by hand. This file is under control of Ansible on {host}.'
      - name: vault_password_file
        value: '{{ semaphore_ansible_cfg_vault_password_file }}'

  roles:
    - thedumbtechguy.mariadb
    - thedumbtechguy.semaphore
    - thedumbtechguy.logrotate
    - thedumbtechguy.configure-self
EOL
    
    echo "Init complete. You can customize the variables by updating './vars.json'."

fi


# execute
if [ "$1" = "execute" ]; then
    
    if [ ! -f vars.json ] || [ ! -f playbook.yml ]; then
        echo "Please run 'init' first!"
    elif ["$(whoami)" == "root"]; then
        echo "Please run as root/sudo"
        exit 1
    elif [ ! -f .g ]; then
        echo "Installing ansible and its dependencies"

        apt-get -y install software-properties-common &&
        apt-get -y install python-software-properties &&
        apt-add-repository -y ppa:ansible/ansible &&
        apt-get -y update &&
        apt-get -y install ansible &&
        ansible-galaxy install thedumbtechguy.mariadb &&
        ansible-galaxy install thedumbtechguy.semaphore &&
        ansible-galaxy install thedumbtechguy.logrotate &&
        ansible-galaxy install thedumbtechguy.configure-self &&

        touch .g
    fi

    if [ ! -f .g ]; then
        echo "Dependencies not satisfied"
        exit 1
    else
        echo "Executing playbook"
        ansible-playbook playbook.yml --extra-vars "@vars.json"
    fi

fi


# help
if [ -z "${1+present}" ] || [ "$1" = "help" ] || [ "$1" = "h" ]; then 

    echo "Usage: sudo sh bootstrap.sh options

Options:  
  - init            initialize required files 
                    You can customize the setup by modifying the generated 'vars.json'
                    Running this command again will generating fresh files.
  - execute:        execute bootstrapping tasks"

fi