# Ansible Role: Semaphore

An ansible role to install and configure [Ansible Semaphore](https://github.com/ansible-semaphore/semaphore)

This role contains a shell script to bootstrap ansible and semaphore. It handles the setup and installation of all required dependencies.

## Requirements

- wget: Required to download `bootstrap.sh`.
- [thedumbtechguy.mariadb](https://galaxy.ansible.com/thedumbtechguy/mariadb/): Required to setup mariadb. Installed if not available.
- [thedumbtechguy.logrotate](https://galaxy.ansible.com/thedumbtechguy/logrotate/): Required to setup logrotate. Installed if not available.

> This role has been tested on `Ubuntu 16.04` and `Ubuntu 16.10` only.

## Bootstrap Installation

If this is a new server, you will want to set the hostname first (`hostname server.domain.tld`).

Copy and run the following command

```shell
sudo apt-get install -y wget &&
  mkdir /tmp/bootstrap &&
  cd /tmp/bootstrap &&
  wget https://raw.githubusercontent.com/thedumbtechguy/ansible-semaphore-bootstrap/master/bootstrap.sh &&
  sudo sh bootstrap.sh init
```

You can then customize the configuration in `vars.json` and run `sudo sh bootstrap.sh execute`.

## Variables

- `semaphore_version`: version to install.
  - Default: `2.3.0`
  - Options:
    - `2.2.0`
    - `2.3.0`
- `semaphore_port`: port to listen on.
  - Default: `3000`

- `semaphore_db_name`: the name of the database to create for semaphore.
  - Default: `semaphore`
- `semaphore_db_auth_user`: the name of the application's database user.
  - Default: `semaphore`
- `semaphore_db_auth_password`: the password of the application's database user.
  - **Required**
- `semaphore_db_auth_privileges`: the privileges to grant the application's database user.
  - Default: `*.*:ALL`

- `semaphore_config_auth_name`: the name of the default semaphore application user.
  - Default: `Admin`
- `semaphore_config_auth_email`: the email of the default semaphore application user.
  - Default: `root@localhost`
- `semaphore_config_auth_username`: the user of the default semaphore application user.
  - Default: `admin`
- `semaphore_config_auth_password`: the password of the default semaphore application user.
  - **Required**

- `semaphore_config_data_dir`: where to store semaphore config and playbook files.
  - Default: `/var/lib/semaphore`
- `semaphore_config_log_path`: where to store log files.
  - Default: `/var/log/semaphore`

- `semaphore_config_email_alerts_enable`: enable email alertss.
  - Default: `no`
- `semaphore_config_email_alerts_server`: smtp server.
  - Default: `localhost`
- `semaphore_config_email_alerts_port`: smtp port.
  - Default: `25`
- `semaphore_config_email_alerts_sender`: email sender address.
  - Default: `semaphore@localhost`
- `semaphore_config_web_root`: the web root which you would use to access the application. used in generating urls in alerts.
  - Default: `http://{{ ansible_fqdn }}:{{ semaphore_port }}/`

- `semaphore_config_telegram_alerts_enable`: enable telegram alerts.
  - Default: `no`
- `semaphore_config_telegram_alerts_bot_token`: get from @BotFather.
  - Default: `''`
- `semaphore_config_telegram_alerts_chat_id`: your telegram chat id.
  - Default: `''`

- `semaphore_config_ldap_enable`: enable ldap authentication.
  - Default: `no`
- `semaphore_config_ldap_server`: ldap server.
  - Default: `localhost`
- `semaphore_config_ldap_port`: ldap port.
  - Default: `389`
- `semaphore_config_ldap_use_tls`: use tls when connecting to the ldap server.
  - Default: `no`
- `semaphore_config_ldap_bind_dn`: bind dn.
  - Default: `cn=user,ou=users,dc=example.tld`
- `semaphore_config_ldap_bind_password`: .
  - Default: `pa55w0rd`
- `semaphore_config_ldap_search_dn`: search dn.
  - Default: `ou=users,dc=example.tld`
- `semaphore_config_ldap_search_filter`: search filter.
  - Default: `(uid=%s)`
- `semaphore_config_ldap_mapping_dn_field`: mapping to dn field.
  - Default: `dn`
- `semaphore_config_ldap_mapping_username_field`: mapping to username field.
  - Default: `uid`
- `semaphore_config_ldap_mapping_fullname_field`: mapping to fullname field.
  - Default: `cn`
- `semaphore_config_ldap_mapping_email_field`: mapping to email field.
  - Default: `mail`

- `semaphore_service_user_name`: account that will run applicatio service. don't run under root.
  - Default: `semaphore`
  > **NOTE**: if user does not exist, a service account will be created.
- `semaphore_service_user_password`: password of account that will run the password service.
  - **Required**
  > **NOTE**: not providing this will allow grant passwordless sudo to the account.
  >
  > password is needed to run local playbooks from semaphore via `become_password`.
  >
  > Password should be an encrypted value compatible with the [ansible user module](http://docs.ansible.com/ansible/user_module.html).
  >
  >  You can create one using: `python -c 'import crypt; print crypt.crypt("This is the password", "$1$ThisIsSomeSalt$")'`

### Bootstrapping

These variables are relevant only to the bootstrapping process and can be modified in the generated `vars.json` file.

- `semaphore_db_admin_home`: directory to store .my.cnf for mariadb.
  - Default: `/root`
- `semaphore_db_admin_user`: database admin username.
  - Default: `admin`
- `semaphore_db_admin_password`: database admin password.
  - **Required**

- `semaphore_ansible_cfg_vault_password`: vault password.
  - Default: `''`
- `semaphore_ansible_cfg_vault_password_file`: location of vault password file.
  - Default: `/var/lib/semaphore/.vpf`

- `semaphore_ansible_cfg_host_key_checking`: enable host key checking.
  - Default: `False`
  - Options:
    - `True`
    - `False`
- `semaphore_ansible_cfg_ansible_managed`: ansible managed string for managed files. used by some roles.
  - Default: `DO NOT MODIFY by hand. This file is under control of Ansible on {host}.`


## Usage Example

```yaml
- hosts: all
  vars:
    semaphore_config_auth_email: 'username@company.tld'
    semaphore_config_auth_password: '4dm1nPa55w0rd'
    semaphore_service_user_password: '$1$ThisIsSo$RwIOJHdSWIzAJjbvBdbOZ0'
    semaphore_ansible_cfg_vault_password: 'pa55w0rd'
  roles:
    - thedumbtechguy.semaphore
```


## License

MIT / BSD

## Author Information

This role was created by [Stefan Froelich](https://thedumbtechguy.blogspot.com/).

## Credits