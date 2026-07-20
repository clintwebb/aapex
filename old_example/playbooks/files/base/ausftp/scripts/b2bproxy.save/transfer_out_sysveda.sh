#!/bin/bash

# Saxon Mailey 2010
# Modified by Dinesh Balendran

if [ $# -lt 3 ]; then
   echo "Usage: $0 <dest host> <dest user> <dest dir> <scp/sftp> <src dir> <delete/nodelete>"
   exit 1
fi

MY_FILE=$(basename $0)
MY_LOG="/tmp/$MY_FILE.`date +%Y%m%d`.log"
ARC_DIR=~/archive/outgoing/

DEST_HOST=$1
DEST_USER=$2
DEST_DIR=$3

if [ "$4" = "sftp" ]; then
	TRAN_TYPE="sftp"
else
	TRAN_TYPE="scp"
fi

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
		echo "$DATESTRING : TRANSFER : ${TRAN_TYPE} : ${FILENAME} to ${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
		if [ "${TRAN_TYPE}" = "sftp" ];
		then
			SFTPBATCH=".sftp.batch.${DATESTRING}"
			echo "put ${FILE} $DEST_DIR" > $SFTPBATCH
			sftp -b $SFTPBATCH ${DEST_USER}@${DEST_HOST}
			RC=$?
		else
			scp -Bp ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}
			RC=$?
		fi
		if [ "$RC" -eq 0 ];
		then
			echo "$DATESTRING : SUCCESS  : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
			echo "$DATESTRING : SUCCESS  : $USER : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}" >> $MY_LOG
                        touch /home/coretx/outgoing/sysveda/coretx.done
                        SFTPBATCH1=".sftp.batch.${DATESTRING}"
                        echo "put /home/coretx/outgoing/sysveda/coretx.done $DEST_DIR" > $SFTPBATCH1
                        sftp -b $SFTPBATCH1 ${DEST_USER}@${DEST_HOST}
                        if [ "$RC" -eq 0 ];
                        then
                             echo "$DATESTRING : SUCCESS  : $TRAN_TYPE PUT coretx.done ${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
                             echo "$DATESTRING : SUCCESS  : $USER : $TRAN_TYPE PUT coretx.done ${DEST_USER}@${DEST_HOST}:${DEST_DIR}" >> $MY_LOG
                        else
                             echo "$DATESTRING : FAILED   : $TRAN_TYPE PUT coretx.done ${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
                             echo "$DATESTRING : FAILED   : $USER : $TRAN_TYPE PUT coretx.done ${DEST_USER}@${DEST_HOST}:${DEST_DIR}" >> $MY_LOG
                        fi 
			if [ $DELETE_SRCFILE -eq 1 ]
			then
				echo "$DATESTRING : DELETE   : ${FILE}"
				rm -vf ${FILE}
			else
				echo "$DATESTRING : ARCHIVE  : ${FILE}"
				mv -v ${FILE} ${ARC_DIR}/${FILENAME}.${DATESTRING}
                                rm -vf /home/coretx/outgoing/sysveda/coretx.done
			fi
		else
			echo "$DATESTRING : FAILED   : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
			echo "$DATESTRING : FAILED   : $USER : $TRAN_TYPE PUT ${FILE} ${DEST_USER}@${DEST_HOST}:${DEST_DIR}" >> $MY_LOG
		fi
	fi
done

