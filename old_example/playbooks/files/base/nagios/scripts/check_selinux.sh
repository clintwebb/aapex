#!/bin/bash
# Saxon Mailey 2021
# saxon@mailey.net.au

# This script checks the status of SELinux

# SETTINGS
DEBUG=0

# CHECK

STATUS="`sestatus | grep 'SELinux status:' | awk '{ print $NF }'`"
MODE="`sestatus | grep 'Current mode:' | awk '{ print $NF }'`"

# EVALUATE

if [ "$STATUS" == "enabled" ]
then
  if [ "$MODE" == "enforcing" ]
  then
    RC=0
  else
    echo "SELINUX IS NOT ENFORCING"
    RC=1
  fi
else
  echo "SELINUX IS NOT ENABLED"
  RC=2
fi

sestatus

exit $RC
