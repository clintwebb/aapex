#!/bin/bash
# Saxon Mailey 2021
# saxon@mailey.net.au

# This script checks the status of the Tenable Nessus agent.

# SETTINGS
DEBUG=0
TMPFILE="/tmp/$$.tenable.check"
NESSUSCLI='/opt/nessus_agent/sbin/nessuscli'

# VARS
INSTALLED=0
RUNNING=0
LINKED=0

# COLLECT DATA
if [ -x $NESSUSCLI ]
then
  INSTALLED=1
  sudo /opt/nessus_agent/sbin/nessuscli agent status > $TMPFILE
else
  INSTALLED=0
fi

if [ $INSTALLED -eq 1 ]
then
  # CHECK DATA
  if [ $DEBUG -gt 0 ]
  then
    GREPFLAGS=''
  else
    GREPFLAGS='-q'
  fi

  grep $GREPFLAGS 'Running: Yes' $TMPFILE
  if [ $? -eq 0 ]
  then
    RUNNING=1
  else
    RUNNING=0
  fi

  grep $GREPFLAGS 'Link status: Connected' $TMPFILE
  if [ $? -eq 0 ]
  then
    LINKED=1
  else
    LINKED=0
  fi

  cat $TMPFILE
else
  echo "Tenable Nessus Agent does not appear to be installed"
fi
  
# EXIT WITH RC
if [ $RUNNING -eq 0 ] || [ $LINKED -eq 0 ] || [ $INSTALLED -eq 0 ]
then
  RC=1
else
  RC=0
fi

# CLEANUP
if [ -f $TMPFILE ]
then
  rm $TMPFILE
fi

exit $RC
