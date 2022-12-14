#!/bin/bash

# Set The Email Variables To Be Used In The cURL Request
gmail_url="smtps://smtp.gmail.com:465"
gmail_from=".com"
gmail_to="com"
gmail_creds=".com:passwordgoeshere"

# Set The File Variable
file_upload="/home/Ansible/Splunk/heavy-forwarders/ansible-os-logs/tmp.txt"

# Set the subject variables

compare_hosts=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-compare.log | grep -C 2 true | awk -F '[][]' '{print $2}' | sort | uniq )

# HTML Message To Send; Basic Format
echo "<html>
<body>
    <div>
	<p>All, </p>
	<p>This email has been sent as a response to an unauthorized change being made on or more of rsyslog servers. </p>
	<p></p>
  <p>Hostname(s):<b> $compare_hosts </b></p>
	<p>Potential Causes for Failure:</p>
	<p>  - Unauthorized configuration changes occurred (changes made manually on the heavy-forwarder instead of using Git.)</p>
	<p></p>
	<p>Please investigate these action items for resolution.</p>
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
mail_to=""
mail_subject=" Issue Detected on $(date)"
mail_reply_to="<replyto> <$gmail_from>"
mail_cc=""

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
log_file1=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-compare.log | base64)
add_file "text/plain" "" "$log_file1" "ansible_compare_error_summary.txt"


log_file2=$(cat ~/Ansible/Splunk/heavy-forwarders/ansible-forwarder-os/checksum-verification.csv | base64)
add_file "text/plain" "" "$log_file3" "checksum_verification.txt"

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
mv ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/ansible-os-compare.log ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/archive/ansible-compare-error-summary-$(date +%Y-%m-%d-%H.%M.%S).log
mv ~/Ansible/Splunk/heavy-forwarders/ansible-forwarder-os/checksum-verification.csv ~/Ansible/Splunk/heavy-forwarders/ansible-os-logs/archive/checksum-verification-summary-$(date +%Y-%m-%d-%H.%M.%S).log
