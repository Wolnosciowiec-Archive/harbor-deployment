#!/bin/bash

#
# Operates on encrypted files
# This method allows to keep the secure files in GIT
# while having the password for them outside.
#

make __check_deployment_password_exists || exit 1
exec ansible-vault --vault-password-file="$(pwd)/keys/deployment_password" "$@"
