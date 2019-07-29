
.SILENT:

IS_ENV_PRESENT=$(shell test -e .env && echo -n yes)

ifeq ($(IS_ENV_PRESENT), yes)
	include .env
	export $(shell sed 's/=.*//' .env)
endif

# Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## This help screen
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET}\t\t%s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Deploy to production server
deploy@prod: __check_deployment_password_exists __update_roles
	make __playbook HOST=production PLAYBOOK=provision

## Deploy FIRST TIME to production server (requires to answer to questions such as what is the password?)
deploy_first_time@prod: __update_roles
	echo -n "Enter SSH user [ENTER]: ";\
	read SSH_USER;\
	echo -n "Enter SSH password [ENTER]: ";\
	read SSH_PASSWORD;\
	make __playbook HOST=production PLAYBOOK=provision ANSIBLE_OPTS="-e ansible_ssh_user=$${SSH_USER} -e enc_filesystem_create_if_not_exists=true -e ansible_ssh_pass=$${SSH_PASSWORD} -e ansible_sudo_pass=$${SSH_PASSWORD} -e ansible_ssh_port=22"

## Connect to any server via SSH
ssh:
	./bin/ssh.py connect

## List all SSH servers credentials
ssh_credentials:
	./bin/ssh.py list

## Update user accounts (basing on users.yml)
update_user_accounts@prod: __check_deployment_password_exists __update_roles
	make __playbook HOST=production PLAYBOOK=users

## Turn on the virtual machine for testing
up@test:
	vagrant up

## Turn off virtual machine
down@test:
	vagrant halt

## Initialize virtual machine
provision@test: __check_deployment_password_exists
	vagrant provision

## Delete test virtual machine
rm@test:
	vagrant destroy -f

## SSH into test server
ssh@test:
	vagrant ssh

## Perform a test deployment
test:
	make up@test || true
	make deploy@test

## Deploy to test server
deploy@test: __check_deployment_password_exists __update_roles
	make __playbook HOST=test PLAYBOOK=provision ANSIBLE_OPTS=-vv

## Decrypt test server
decrypt@test: __check_deployment_password_exists __update_roles
	make __playbook HOST=test PLAYBOOK=provision ANSIBLE_OPTS="-vv -t decrypt"

## Update user accounts (basing on users.yml) at test server
update_user_accounts@test: __check_deployment_password_exists __update_roles
	make __playbook HOST=test PLAYBOOK=users

__playbook:
	/bin/bash -c "time ansible-playbook ./playbook.${PLAYBOOK}.yml -i hosts.cfg ${ANSIBLE_OPTS} --vault-password-file='$$(pwd)/keys/deployment_password' --limit ${HOST}"

__check_deployment_password_exists:
	@if [[ ! -f ./keys/deployment_password ]]; then \
		echo " >> You need to put the deployment password at ./keys/deployment_password";\
		echo " >> Remember, the file should contain only the password, without any blank spaces and new lines";\
		exit 1; \
	fi

__update_roles:
	printf " >> Making sure the Ansible roles from Ansible Galaxy are up to date\n"
	./bin/update-roles.py
	printf " >> Done.\n"

_update_galaxy_role:
	make _sure_repository_present_with_recent_version REPO_DIR="~/.ansible/roles/$${NAME}" REVISION=$${REVISION} REPO_URL=$${REPO_URL}

_sure_repository_present_with_recent_version:
	if [[ -d ${REPO_DIR} ]]; then\
		cd ${REPO_DIR} && git checkout ${REVISION} > /dev/null && git pull > /dev/null;\
	else\
		git clone ${REPO_URL} -b ${REVISION} ${REPO_DIR} > /dev/null; \
	fi
