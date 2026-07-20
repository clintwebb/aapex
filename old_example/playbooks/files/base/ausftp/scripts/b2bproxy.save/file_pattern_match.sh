#!/bin/bash

# DINESH B - MATCH CURRENT DATE AS PART OF THE FILE NAME PATTERN ON THE FILENAMES AT THE DESTINATION. IF FOUND THEN PUT A TRIGGER FILE CALLED WEB2.DONE 

 # DEFINE SERVER DETAILS
   server="sftp-main.uat.ausiex.com.au"
   username="coretx"
   remote_coretx_path="/"
   source_get_path="/home/coretx"

 # SFTP CONNECT TO DESTINATION AND GRAB DETAILS OF THE FILES
   sftp coretx@sftp-main.uat.ausiex.com.au:/Accounts <<< "ls -l" > accounts_output
   sleep 3s
   sftp coretx@sftp-main.uat.ausiex.com.au:/AdviserRelationship <<< "ls -l" > adviserrelationship_output
   sleep 3s
   sftp coretx@sftp-main.uat.ausiex.com.au:/ClientLegalEntity <<< "ls -l" > clientlegalentity_output
   sleep 3s
   sftp coretx@sftp-main.uat.ausiex.com.au:/LegalEntities <<< "ls -l" > legalentities_output
   sleep 3s
   sftp coretx@sftp-main.uat.ausiex.com.au:/Clients <<< "ls -l" > clients_output
   sleep 2s


# DEFINE THE FILES CONTAINING THE LS OUTPUT
  ls_output_file="/home/coretx/accounts_output"
  ls_output_file1="/home/coretx/adviserrelationship_output"
  ls_output_file2="/home/coretx/clientlegalentity_output"
  ls_output_file3="/home/coretx/legalentities_output"
  ls_output_file4="/home/coretx/clients_output"


  # set current date and file pattern variables
    current_date=$(date +'%Y%m%d')
    file_pattern="${current_date}"


  # SEARCH FOR THE FILE PATTERN IN ALL OF THE EXTRACTED FILES....
    result=$(grep -q -E "accounts.*${file_pattern}.*" "$ls_output_file" && echo TRUE || echo FALSE)
    result1=$(grep -q -E "adviserrelationship.*${file_pattern}.*" "$ls_output_file1" && echo TRUE || echo FALSE)
    result2=$(grep -q -E "clientlegalentity.*${file_pattern}.*" "$ls_output_file2" && echo TRUE || echo FALSE)
    result3=$(grep -q -E "legalentities.*${file_pattern}.*" "$ls_output_file3" && echo TRUE || echo FALSE)
    result4=$(grep -q -E "clients.*${file_pattern}.*" "$ls_output_file4" && echo TRUE || echo FALSE)

    # CHECK IF ALL THE RESULT VARIABLES CONTAINS TRUE
      if [ "$result" == "TRUE" ] || [ "$result1" == "TRUE" ] || [ "$result2" == "TRUE" ] || [ "$result3" == "TRUE" ] || [ "$result4" == "TRUE" ]; then
         # IF ALL TRUE, PUT A WEB2.DONE FILE
           echo "File pattern found. put web2.done."
           # PUT WEB2.DONE FILE IN CORETX DIRECTORY IN DESTINATION
             touch "$source_get_path/web2.done"
             echo "put $source_get_path/web2.done $remote_coretx_path" >> sftp_batch
             echo "exit" >> sftp_batch
             sftp -b sftp_batch $username@$server
      else
         echo "File pattern not found."
      fi

  # CLEAN-UP
    rm -f "$source_get_path/web2.done"
    rm -f sftp_batch
    rm -f "$ls_output_file"
    rm -f "$ls_output_file1"
    rm -f "$ls_output_file2"
    rm -f "$ls_output_file3"
    rm -f "$ls_output_file4"
