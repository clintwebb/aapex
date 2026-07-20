#!/bin/bash

if [ $# -lt 3 ]; then
   echo "Usage: $0 <dest host> <dest user> <dest pass> <dest dir> <src dir> <delete/nodelete>"
   exit 1
fi

MY_FILE=$(basename $0)
MY_LOG=~/logs/$MY_FILE.`date +%Y%m%d`.log

DEST_HOST=$1
DEST_USER=$2
DEST_PASS=$3
DEST_DIR=$4
SRC_DIR=$5

# If SRC_DIR isn't specified, then apply a default
test -z "$SRC_DIR" && SRC_DIR=~/outgoing/

ARC_DIR=~/archive/$SRC_DIR
test -d $ARC_DIR || mkdir -p $ARC_DIR

if [ "$6" = "delete" ]; then
        DELETE_SRCFILE=1
else
        DELETE_SRCFILE=0
fi

DATESTRING=`date +%Y%m%d%H%M%S`
echo "$DATESTRING : SEARCH   : ${SRC_DIR}"

# -----------------------------------------------------------------------------

if [ ! -d ${SRC_DIR} ]; then
  echo "Source directory doesn't exist: ${SRC_DIR}"
  exit 1
fi

for FILE in ${SRC_DIR}/*; do
#        FILE=$SRC_DIR/$FILENAME
        FILENAME=$(basename "$FILE")
        if [ -f "$FILE" ];
        then
                echo "$DATESTRING : TRANSFER : ${TRAN_TYPE} : ${FILENAME} to ${DEST_USER}@${DEST_HOST}:${DEST_DIR}/"

                # Batch file constructor
                SFTPBATCH=".sftp.batch.${DATESTRING}"
                echo "put "${FILE}" $DEST_DIR/" > $SFTPBATCH
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

                if [[ "$EXEC" =~ "No such file or directory" ]]; then
                        RC=1
                else

	                # the sftp batch file contains "ls $DEST_DIR"
	                # if the expect results contain the filename then we can
        	        # assume that the file exists on the destination sftp server
        	        [[ "$EXEC" =~  "$DEST_DIR/$FILENAME" ]] && RC=0 || RC=1
		fi

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

