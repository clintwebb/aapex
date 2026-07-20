#!/bin/bash
# Author: Clinton Webb (webb.clint@gmail.com)
# Date: April 14, 2022.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <dnsentry> [warning:30] [critical:15] [port:443]"
  echo "Note: in order to provide a port, warning and critical fields must be entered"
  exit 1
fi

ENTRY="$1"
WARNLIMIT=${2:-30}
CRITLIMIT=${3:-15}
PORT=${4:-443}
TIMEOUT=${TIMEOUT:-10}

# get the Cert details from the endpoint
OUTPUT=$(echo |timeout ${TIMEOUT}s openssl s_client -connect $ENTRY:$PORT -servername $ENTRY 2>/dev/null|openssl x509 -noout -text 2>/dev/null|grep "Not After")
if [[ $? -gt 0 ]]; then
  echo "Connection failed to $ENTRY:$PORT"
  exit 2
fi

TRIMMED=$(echo "$OUTPUT"|cut -d : -f 2,3,4,5)
SSL_DATE=$(date +%s -d "$TRIMMED")
CUR_DATE=$(date +%s)

DAYS_SEC=$(( SSL_DATE - CUR_DATE ))
DAYS=$(( $DAYS_SEC / 86400 ))

echo "Certificate expires in $DAYS days"
echo "Expiry Date: $TRIMMED"

if [[ $DAYS -le $CRITLIMIT ]]; then
  # CRITICAL
  exit 2
else
  if [[ $DAYS -le $WARNLIMIT ]]; then
    # WARNING
    exit 1
  else
    # OK
    exit 0
  fi
fi

