#!/usr/bin/env bash

echo "Removing files starting with other_ on all Splunk Heavy Forwarders..."

ansible-playbook -i inventory.yml ansible-os-remove-other.yml

