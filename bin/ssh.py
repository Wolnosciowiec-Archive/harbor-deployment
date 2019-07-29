#!/usr/bin/env python3

import os
import subprocess
import yaml
import sys


class SSH:
    _path: str
    _dirs = ['group_vars', 'host_vars']
    _decrypt_command = './vault.sh view %s'
    _credentials: dict

    def __init__(self):
        self._path = os.path.dirname(os.path.abspath(__file__)) + '/../'
        self._credentials = {}
        self._parse_all()

    def get_credentials(self):
        return self._credentials

    def connect(self):
        print('==> Available hosts:')

        for host, options in self._credentials.items():
            print('- %s' % host)

        print('')
        host_name = input('Please select a host: ')

        if not host_name in self._credentials:
            print(' (!) Invalid choice')
            sys.exit(1)

        credentials = self._credentials.get(host_name)

        print('==> Connecting to %s' % host_name)

        if credentials['sudo'] and credentials['user'] != 'root':
            print('==> Sudo password is %s' % credentials['sudo'])

        self._credentials = {}
        os.system('sshpass -p "%s" ssh -p %s %s@%s' % (
            credentials['password'],
            credentials['port'],
            credentials['user'],
            credentials['host']
        ))

    def _parse_all(self):
        for directory in self._dirs:
            dir_path = self._path + '/' + directory

            if not os.path.isdir(dir_path):
                continue

            files = os.scandir(dir_path)
            for file in files:
                self._parse_file(file.path)

    def _parse_file(self, path: str):
        decrypted = subprocess.check_output(self._decrypt_command % path, shell=True)
        parsed = yaml.load(decrypted, Loader=yaml.SafeLoader)

        host = parsed.get('ansible_ssh_host', os.path.basename(path))
        self._credentials[host] = {
            'host': host,
            'password': parsed.get('ansible_ssh_pass', ''),
            'user': parsed.get('ansible_ssh_user', 'root'),
            'port': parsed.get('ansible_ssh_port', '22'),
            'sudo': parsed.get('ansible_sudo_pass', '')
        }


ssh = SSH()
option = sys.argv[1] if len(sys.argv) > 1 else 'help'

if option == 'list':
    print(ssh.get_credentials())
elif option == 'connect':
    ssh.connect()
else:
    print('Available options: list, connect')
