#!/usr/bin/env bash

# This script is triggered when changes are detected between the local Ansible repository
# and the GitLab repository

echo "Running Ansible Syslog Backup Script  now..."
ansible-playbook -i inventory.yml ansible-os-rsyslog-backup.yml 

