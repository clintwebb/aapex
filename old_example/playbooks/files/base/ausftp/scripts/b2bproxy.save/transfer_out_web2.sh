#!/bin/bash

# DINESH B - CHECK WITH HIM IF MAKING ANY CHANGES

MY_FILE=$(basename $0)
MY_LOG="/tmp/$MY_FILE.`date +%Y%m%d`.log"
ARC_DIR=~/archive/outgoing/

DEST_HOST=$1
DEST_USER=$2
remote_coretx_path="/"

# LIST OF DESTINATION DIRECTORIES AND THEIR FULL PATHS
DEST_DIR1="/Accounts"
DEST_DIR2="/AdviserRelationship"
DEST_DIR3="/ClientLegalEntity"
DEST_DIR4="/Clients"
DEST_DIR5="/LegalEntities"

# LIST OF SOURCE DIRECTORIES AND THEIR FULL PATHS
SRC_DIR1="/home/coretx/outgoing/web2/Accounts"
SRC_DIR2="/home/coretx/outgoing/web2/AdviserRelationship"
SRC_DIR3="/home/coretx/outgoing/web2/ClientLegalEntity"
SRC_DIR4="/home/coretx/outgoing/web2/Clients"
SRC_DIR5="/home/coretx/outgoing/web2/LegalEntities"


DATESTRING=`date +%Y%m%d%H%M%S`
echo "$DATESTRING : SEARCH   : ${SRC_DIR1}"
echo "$DATESTRING : SEARCH   : ${SRC_DIR2}"
echo "$DATESTRING : SEARCH   : ${SRC_DIR3}"
echo "$DATESTRING : SEARCH   : ${SRC_DIR4}"
echo "$DATESTRING : SEARCH   : ${SRC_DIR5}"

# -----------------------------------------------------------------------------

# INITIALIZE A FLAG TO TRACK IF ALL DIRECTORIES HAVE FILES
ALL_DIRS_HAVE_FILES=1

# CREATE A SFTP BATCH FILE
SFTP_BATCH=".sftp.batch.${DATESTRING}"

# LOOP THROUGH EACH DIRECTORY AND CONVERT FILES TO UTF-8
for DIRECTORY in "$SRC_DIR1" "$SRC_DIR2" "$SRC_DIR3" "$SRC_DIR4" "$SRC_DIR5"; do
    for FILE in "$DIRECTORY"/*.txt; do
        if [[ -e $FILE ]]; then
            echo "Processing $FILE" >> /home/coretx/convertion_log
            echo "Before conversion:" >> /home/coretx/convertion_log
            cat "$FILE" >> /home/coretx/convertion_log
            iconv -f WINDOWS-1252 -t UTF-8 -o "$FILE.new" "$FILE" && mv -f "$FILE.new" "$FILE"
            echo "After conversion:" >> /home/coretx/convertion_log
            cat "$FILE" >> /home/coretx/convertion_log
            echo "Encoding done for $FILE" >> /home/coretx/convertion_log
            echo "DONE FOR THE BATCH" >> /home/coretx/convertion_log
        fi
    done
done

# LOOP THROUGH EACH DIRECTORY AND IF FIND AT LEAST ONE TXT FILE IN THE CURRENT DIRECTORY, SET THE FLAG TO ONE AND EXIT THE INNER LOOP
for DIRECTORY in "$SRC_DIR1" "$SRC_DIR2" "$SRC_DIR3" "$SRC_DIR4" "$SRC_DIR5"; do
    DIRECTORY_HAS_FILES=
    for FILE in "$DIRECTORY"/*.txt; do
        DIRECTORY_HAS_FILES=1
        break
    done
    if [ -z "$DIRECTORY_HAS_FILES" ]; then
        ALL_DIRS_HAVE_FILES=
        break
    fi
done

# IF ALL DIRECTORIES HAVE FILES, ADD SFTP COMMANDS TO THE BATCH FILE
if [ -n "$ALL_DIRS_HAVE_FILES" ]; then
    for DIRECTORY in "$SRC_DIR1" "$SRC_DIR2" "$SRC_DIR3" "$SRC_DIR4" "$SRC_DIR5"; do
        # CHECK WHICH DIRECTORY IS BEING PROCESSED AND ASSIGN THE CORRESPONDING DESTINATION DIRECTORY
        if [ "$DIRECTORY" == "$SRC_DIR1" ]; then
            DEST_DIR="$DEST_DIR1"
        elif [ "$DIRECTORY" == "$SRC_DIR2" ]; then
            DEST_DIR="$DEST_DIR2"
        elif [ "$DIRECTORY" == "$SRC_DIR3" ]; then
            DEST_DIR="$DEST_DIR3"
        elif [ "$DIRECTORY" == "$SRC_DIR4" ]; then
            DEST_DIR="$DEST_DIR4"
        elif [ "$DIRECTORY" == "$SRC_DIR5" ]; then
            DEST_DIR="$DEST_DIR5"
        fi

        # Convert files to UTF-8 
        ## for f in "$DIRECTORY"/*.txt; do iconv -f WINDOWS-1252 -t UTF-8 -o "$f.new" "$f" && mv -f "$f.new" "$f"; done

        # APPEND THE SFTP COMMAND TO THE BATCH FILE
        echo "put \"$DIRECTORY\"/*.txt" "$DEST_DIR" >> "$SFTP_BATCH"
        
    done

  # EXECUTE THE SFTP BATCH FILE
   sftp -b "$SFTP_BATCH" "$DEST_USER@$DEST_HOST"
   RC=$?
   echo "FILES TRANSFERRED SUCCESSFULLY!"
else
    echo "SOME DIRECTORIES ARE EMPTY OR MISSING FILES. NO FILES TRANSFERRED. INVESTIGATE THE ISSUE"
fi

if [ "$RC" -eq 0 ]; then
        echo "ALL FILES HAVE BEEN TRANSFERRED PUT WEB2.DONE FILE"
        # ARCHIVE FILES
        /usr/bin/find ~/outgoing/web2/ -type f -name '*.txt' -exec mv {} ~/archive/outgoing \; >> ~/logs/archive.`date +\%Y\%m\%d`
        
        touch "/home/coretx/outgoing/web2/web2.done"
        echo "put /home/coretx/outgoing/web2/web2.done $remote_coretx_path" >> sftp_done
        echo "exit" >> sftp_done
        sftp -b sftp_done "$DEST_USER@$DEST_HOST"
        rm -f /home/coretx/outgoing/web2/web2.done
        rm -f /home/coretx/sftp_done
fi
