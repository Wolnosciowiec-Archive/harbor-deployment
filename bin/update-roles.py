#!/usr/bin/env python3

import os
import yaml


class UpdateRoles:
    _path: str
    _parsed: dict

    def __init__(self):
        self._path = os.path.dirname(os.path.abspath(__file__)) + '/../roles-at-git.yaml'
        self._parsed = {}
        self._parse_roles()

    def _parse_roles(self):
        if not os.path.isfile(self._path):
            raise Exception('roles-at-git.yaml must be present at project root directory')

        with open(self._path, 'rb') as f:
            self._parsed = yaml.load(f.read(), Loader=yaml.SafeLoader)

    def update(self):
        for name, role in self._parsed['roles'].items():
            print('>> Updating %s' % name)

            os.system('cd $(dirname %s) && make _update_galaxy_role REVISION=%s REPO_URL=%s NAME=%s' % (
                self._path, role.get('version'), role.get('url'), name
            ))


UpdateRoles().update()
