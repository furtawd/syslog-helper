#!/bin/bash

# Set The Email Variables To Be Used In The cURL Request
gmail_url="smtps://smtp.gmail.com:465"
gmail_from=""
gmail_to="me"
gmail_creds="passgoeshere"

# Set The File Variable
file_upload="/home/Ansible/Splunk/heavy-forwarders/ansible-os-logs/tmp.txt"

# Set the subject variables

rsyslog_hosts=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-rsyslog-restart.log  | grep error -C 12 | grep -oP 'ok:\s\[.*?\]' | awk -F '[][]' '{print $2}')

# HTML Message To Send; Basic Format
echo "<html>
<body>
    <div>
	<p>All, </p>
	<p>This email has been sent as a response to an action being required on one or more of the Splunk Heavy Forwarders rsyslog component. </p>
	<p></p>
  <p>Hostname(s):<b> $rsyslog_hosts</b></p>
	<p>Potential Causes for Failure:</p>
	<p>  - An issue with the rsyslog service not restarting properly. </p>
	<p>  - A configuration change made to rsyslog that is invalid or contains errors. </p>
	<p></p>
	<p>Please investigate the attached log for troubleshooting. For a temporary fix, please revert to the previous working .conf file.</p>
  <p><a href="https://www.rsyslog.com/doc/v8-stable/configuration/index.html">rsyslog Configuration Manual</a></p>
	<p></p>
	<p>Thank you,</p>
	<p>- Ansible Automation</p>
    <p></p>
	<p></p>
    </div>
</body>
</html>" > ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/message.html

# Set Additional Email Variables To Be Used In The cURL Request
mail_from=".com <$gmail_from>"
mail_to=" <$gmail_to>"
mail_subject= "rsyslog Configuration/Service - Issues Detected on $(date)"
mail_reply_to=".com <$gmail_from>"
mail_cc=".com"

# Add An Image To tmp.txt :
# $1 : type (ex : image/png)
# $2 : image content id filename (match the cid:filename.png in html document)
# $3 : image content base64 encoded
# $4 : filename for the attached file if content id filename empty
function add_file {
    echo "--MULTIPART-MIXED-BOUNDARY
Content-Type: $1
Content-Transfer-Encoding: base64" >> "$file_upload"

    if [ ! -z "$2" ]; then
        echo "Content-Disposition: inline
Content-Id: <$2>" >> "$file_upload"
    else
        echo "Content-Disposition: attachment; filename=$4" >> "$file_upload"
    fi
    echo "$3

" >> "$file_upload"
}

message_base64=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/message.html | base64)

# Converts Multiple Parts Of The Email Into Base64
echo "From: $mail_from
To: $mail_to
Subject: $mail_subject
Reply-To: $mail_reply_to
Cc: $mail_cc
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"MULTIPART-MIXED-BOUNDARY\"

--MULTIPART-MIXED-BOUNDARY
Content-Type: multipart/alternative; boundary=\"MULTIPART-ALTERNATIVE-BOUNDARY\"

--MULTIPART-ALTERNATIVE-BOUNDARY
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: base64
Content-Disposition: inline

$message_base64
--MULTIPART-ALTERNATIVE-BOUNDARY--" > "$file_upload"

# Add The Ansible Log Files

log_file1=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-rsyslog-restart.log | base64)
add_file "text/plain" "" "$log_file1" "ansible_restart_error_summary.txt"



# End Of Uploaded File
echo "--MULTIPART-MIXED-BOUNDARY--" >> "$file_upload"

# Send Email Via cURL Request
echo "sending ...."
curl --tlsv1.2 \
     --url "$gmail_url" \
     --user "$gmail_creds" \
     --mail-from "$gmail_from" \
     --mail-rcpt "$gmail_to" \
     -T "$file_upload"
res=$?
if test "$res" != "0"; then
   echo "Sending failed with: $res"
else
    echo "OK"
fi

sleep 5

# Performing Clean-Up In The 'logs/' Directory
rm -f ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/message.html
rm -f ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/tmp.txt
mv ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-rsyslog-restart.log ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/archive/ansible-restart-error-summary-$(date +%Y-%m-%d-%H.%M.%S).log
