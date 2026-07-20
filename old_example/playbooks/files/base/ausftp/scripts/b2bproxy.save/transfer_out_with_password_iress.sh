#!/bin/bash

if [ $# -lt 3 ]; then
   echo "Usage: $0 <dest host> <dest user> <dest pass> <dest dir> <src dir> <delete/nodelete>"
   exit 1
fi

MY_FILE=$(basename $0)
MY_LOG=~/logs/$MY_FILE.`date +%Y%m%d`.log
ARC_DIR=~/archive/outgoing/

DEST_HOST=$1
DEST_USER=$2
DEST_PASS=$3
DEST_DIR=$4

if [ "A$5" = "A" ]; then
        SRC_DIR=~/outgoing/
else
        SRC_DIR="$5"
fi

if [ "$6" = "delete" ]; then
        DELETE_SRCFILE=1
else
        DELETE_SRCFILE=0
fi

DATESTRING=`date +%Y%m%d%H%M%S`
echo "$DATESTRING : SEARCH   : ${SRC_DIR}"

# -----------------------------------------------------------------------------

for FILENAME in `ls ${SRC_DIR}`; do
        FILE=$SRC_DIR/$FILENAME
        if [ -f "$FILE" ];
        then
                echo "$DATESTRING : TRANSFER : ${TRAN_TYPE} : ${FILENAME} to ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/"

                # Batch file constructor
                SFTPBATCH=".sftp.batch.${DEST_USER}.${DATESTRING}"
                echo "put ${FILE} $DEST_DIR/" > $SFTPBATCH
                echo "ls $DEST_DIR" >> $SFTPBATCH
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

                # the sftp batch file contains "ls $DEST_DIR"
                # if the expect results contain the filename then we can
                # assume that the file exists on the destination sftp server
                [[ "$EXEC" =~  $DEST_DIR/$FILENAME ]] && RC=0 || RC=1

                if [ "$RC" -eq 0 ];
                then
                        echo "$DATESTRING : SUCCESS  : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/"
                        echo "$DATESTRING : SUCCESS  : $USER : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/" >> $MY_LOG
                        if [ $DELETE_SRCFILE -eq 1 ]
                        then
                                echo "$DATESTRING : DELETE   : ${FILE}" >> $MY_LOG
                                rm -vf ${FILE}
                        else
                                echo "$DATESTRING : ARCHIVE  : ${FILE}" >> $MY_LOG
                                mv -v ${FILE} ${ARC_DIR}/${FILENAME}.${DATESTRING} >> $MY_LOG
                        fi
                else
                        echo "$DATESTRING : FAILED   : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/"
                        echo "$DATESTRING : FAILED   : $USER : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/" >> $MY_LOG
                fi
        fi
done
echo "$DATESTRING : END"

