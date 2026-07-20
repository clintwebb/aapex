
#!/bin/bash

if [ $# -lt 3 ]; then
 #  echo "Usage: $0 <dest host> <dest user> <dest pass> <dest dir> <src dir><delete/nodelete>"
echo "This script performs an mget for all files, if local destination is omitted incoming will be used" 
echo "Usage: $0 <dest host> <dest user> <dest pass> <remote src dir> <local dest dir>"
   exit 1
fi

MY_FILE=$(basename $0)
MY_LOG=~/logs/$MY_FILE.`date +%Y%m%d`.log
ARC_DIR=~/archive/incoming/

DEST_HOST=$1
DEST_USER=$2
DEST_PASS=$3
DEST_DIR=$4

if [ "A$5" = "A" ]; then
        SRC_DIR=~/incoming/
else
        SRC_DIR="$5"
fi

if [ "$6" = "delete" ]; then
        #DELETE_SRCFILE=1
		DELETE_SRCFILE=0
else
        DELETE_SRCFILE=0
fi

DATESTRING=`date +%Y%m%d%H%M%S`
#echo "$DATESTRING : SEARCH   : ${SRC_DIR}"

# -----------------------------------------------------------------------------


				echo "$DATESTRING : TRANSFER : ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/* TO $SRC_DIR"
                # Batch file constructor
                SFTPBATCH=".sftp.batch.${DATESTRING}"
                echo "mget $DEST_DIR/* $SRC_DIR" > $SFTPBATCH
                # echo "ls $DEST_DIR" >> $SFTPBATCH
                echo "exit" >> $SFTPBATCH

                # Execute expect script to SFTP and pump results to $EXEC
                # execute with -d to debug
                EXEC=$(expect -c "
                        set timeout 300
                        spawn sftp -o \"BatchMode no\" -b $SFTPBATCH $DEST_USER@$DEST_HOST
                        expect \"*assword:\"
                        send \"$DEST_PASS\r\"
                        expect \"sftp>\"
                        send \"\r\"
                        expect \"sftp>\"
                        send "bye\r"
                        expect eof
                        exit
                     ")
                echo -e "\n\n$EXEC\n\n"
                rm $SFTPBATCH

echo "$DATESTRING : END"

