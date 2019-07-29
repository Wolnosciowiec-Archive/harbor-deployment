Harbor Deployment template
==========================

Ansible project structure, with automation scripts.

## Requirements

- Ansible
- Ansible Vault
- Makefile
- Python 3
- GIT
- sshpass
- Bash
- PyYAML (`pip3 install PyYAML`)

## Scripts

### SSH

Connect to a SSH server without knowing credentials.

```bash
make ssh
```

### Update all roles stored in git repositories

At first collect your ansible roles that you store in separate git repositories, and put them in `./roles-at-git.yaml` file.

Then execute:

```bash
make _update_roles
```

```bash
➜  harbor-deployment git:(master) ✗ make __update_roles
 >> Making sure the Ansible roles from Ansible Galaxy are up to date
>> Updating blackandred.server_multi_user
Already on 'master'
>> Updating blackandred.server_docker_project
Already on 'master'
>> Updating blackandred.server_secure_storage
Already on 'master'
>> Updating blackandred.server_ssh_fallback_port
Already on 'master'
>> Updating blackandred.server_basic_security
Already on 'master'
>> Updating blackandred.server_basic_software
Already on 'master'
 >> Done.
```
