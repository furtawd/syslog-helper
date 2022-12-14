#!/usr/bin/env bash

# This script is triggered if there are no changes between the local Ansible repository \
# and the GitLab repository

time=$(date +"%T")
day=$(date +"%m/%d/%Y")
echo ""
echo "===================================================================================================================="
echo "GitLab Status: No changes have been detected between the GitLab project repository and the local project repository."
echo "Current Date: $day"
echo "Current Time: $time"
echo "===================================================================================================================="
echo ""


