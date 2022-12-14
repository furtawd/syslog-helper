#!/usr/bin/env bash

# This script is triggered when new files are copied to each Splunk Heavy Forwarder

echo "Restarting rsyslog on all Splunk Heavy Forwarders..."
ansible-playbook -i inventory.yml ansible-os-rsyslog-restart.yml



