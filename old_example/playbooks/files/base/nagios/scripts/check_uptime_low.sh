#!/bin/bash
# Saxon Mailey 2021
# saxon@mailey.net.au

CHECK_UPTIME='/usr/lib64/nagios/plugins/check_uptime'

# CHECK PARAMS

if ! [[ "$1" =~ ^[0-9]+$ ]]
then
  echo "ERROR: warning value is not numeric"
  RC=97
else
  if ! [[ "$2" =~ ^[0-9]+$ ]]
  then
    echo "ERROR: warning value is not numeric"
    RC=97
  else
    if [[ $1 -lt $2 ]]
    then
      echo "ERROR: warning threshold must be greater than critical"
      RC=99
    fi
 fi
fi

if [[ "$RC" != "" ]]
then
  echo "LOW UPTIME CHECK"
  echo "$0 [warning threshold in minutes] [critical threshold in minutes]"
  exit $RC
fi

# GET UPTIME

UPTIME=`$CHECK_UPTIME | cut -d '=' -f 2`
UPTIME=`echo $UPTIME | cut -d '.' -f 1`
UPTIME_PRETTY="`uptime -p`"

# CHECK IF WARNING

if [[ $UPTIME -lt $1 ]]
then
  if [[ $UPTIME -lt $2 ]]
  then
    echo "CRITICAL: UPTIME LOW ($UPTIME_PRETTY)"
    RC=2
  else
    echo "WARNING: UPTIME LOW ($UPTIME_PRETTY)"
    RC=1
  fi
else
  RC=0
  echo "OK: $UPTIME_PRETTY"
fi

exit $RC
