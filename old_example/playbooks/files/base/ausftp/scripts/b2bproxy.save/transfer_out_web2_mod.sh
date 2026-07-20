#!/bin/bash

# DINESH B - CHECK WITH HIM IF MAKING ANY CHANGES

MY_FILE=$(basename $0)
MY_LOG="/tmp/$MY_FILE.`date +%Y%m%d`.log"
ARC_DIR=~/archive/outgoing/
RC=1

DEST_HOST=$1
DEST_USER=$2
remote_coretx_path="/"

# LIST OF DIRECTORIES TO PROCESS
# Note: SOURCE AND DESTINATION'S MATCH
declare -a DIRS=(Accounts AdviserRelationship ClientLegalEntity Clients LegalEntities)

SRC="/home/coretx/outgoing/web2/"
#SRC="/home/coretx/outgoing/web2_test/"

DATESTRING=`date +%Y%m%d%H%M%S`
for AA in ${DIRS[@]}; do echo "$DATESTRING : SEARCH   : ${AA}"; done

# -----------------------------------------------------------------------------

# INITIALIZE A FLAG TO TRACK IF ALL DIRECTORIES HAVE FILES
ALL_DIRS_HAVE_FILES=0
for DIRECTORY in ${DIRS[@]}; do
    for FILE in ${SRC}${DIRECTORY}/*.txt; do
        if [[ -e $FILE ]]; then
          ALL_DIRS_HAVE_FILES=$((ALL_DIRS_HAVE_FILES + 1))
          break;
        fi
    done
done


# CREATE A SFTP BATCH FILE
SFTP_BATCH=".sftp.batch.${DATESTRING}"

if [[ $ALL_DIRS_HAVE_FILES -eq ${#DIRS[*]} ]]; then

  # LOOP THROUGH EACH DIRECTORY, CONVERT FILES TO UTF-8, AND ADD TO BATCH
  for DIRECTORY in ${DIRS[@]}; do
    for FILE in ${SRC}${DIRECTORY}/*.txt; do
        if [[ -e $FILE ]]; then
            echo "Processing $FILE"
            if [[ -e "$FILE.converted" ]]; then
              echo "File $FILE already converted"
            else
              iconv -c -f WINDOWS-1252 -t UTF-8 -o "$FILE.new" "$FILE"
              if [[ $? -gt 0 ]]; then
                echo "Failure....  Probably because it already converted to UTF-8... send anyway"
              else
                diff "$FILE" "$FILE.new"
                if [[ $? -eq 1 ]]; then
                  # File has changed, so over-write original
                  mv -f "$FILE.new" "$FILE"
                  touch "$FILE.converted"
                fi
              fi
              [[ -e "$FILE.new" ]] && rm "$FILE.new"
            fi
        fi
    done

    echo "put \"${SRC}${DIRECTORY}\"/*.txt" "/$DIRECTORY" >> "$SFTP_BATCH"
  done

  # EXECUTE THE SFTP BATCH FILE
   sftp -b "$SFTP_BATCH" "$DEST_USER@$DEST_HOST"
   RC=$?

   rm "$SFTP_BATCH"
else
    ### Do you need to report if some directories were empty?  Do you need to verify that there is at least one file in each directory?
    echo "SOME DIRECTORIES ARE EMPTY OR MISSING FILES. NO FILES TRANSFERRED. INVESTIGATE THE ISSUE"
fi

if [[ "${RC:-1}" -eq 0 ]]; then

        /usr/bin/find ~/outgoing/web2/ -type f -name '*.txt.converted' -delete >> ~/logs/archive.`date +\%Y\%m\%d`
  
        echo "ALL FILES HAVE BEEN TRANSFERRED PUT WEB2.DONE FILE"
        # ARCHIVE FILES
        /usr/bin/find ~/outgoing/web2/ -type f -name '*.txt' -exec mv {} ~/archive/outgoing \; >> ~/logs/archive.`date +\%Y\%m\%d`
        
        touch "/home/coretx/outgoing/web2/web2.done"
        echo "put /home/coretx/outgoing/web2/web2.done $remote_coretx_path" >> sftp_done
        echo "exit" >> sftp_done
        sftp -b sftp_done "$DEST_USER@$DEST_HOST"
        rm -f /home/coretx/outgoing/web2/web2.done
        rm -f /home/coretx/sftp_done
else
  echo "Transfer Failed!!"
fi
