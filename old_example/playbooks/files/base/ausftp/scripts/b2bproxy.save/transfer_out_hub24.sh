#!/bin/bash

#Jeremy Stafford 2022

sftp -i /home/hub24/.ssh/id_rsa.pem ausiex@uatsftp.hubconnect.com.au <<EOF
put /home/hub24/*.txt.pgp /from_ausiex
bye
EOF
mv /home/hub24/*.pgp /home/hub24/transfered/
exit
