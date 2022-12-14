#!/usr/bin/env bash

cd ~/Ansible/Splunk/heavy-forwarders/ansible-forwarder-os
ansible-playbook -i inventory.yml ansible-os-main.yml 2>&1 | tee ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-summary.txt
