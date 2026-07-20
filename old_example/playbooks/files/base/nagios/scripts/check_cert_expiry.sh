#!/bin/bash
# Author: Clinton Webb (webb.clint@gmail.com)
# Date: June 2, 2023.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <certfile.pem> [WARN] [CRIT]"
  echo "Note: WARN and CRIT are days."
  exit 1
fi

ENTRY="$1"
WARNLIMIT=${2:-30}
CRITLIMIT=${3:-15}

# get the Cert details from the file
OUTPUT=$(openssl x509 -noout -text -in "$ENTRY" 2>/dev/null|grep "Not After")
if [[ $? -gt 0 ]]; then
  echo "Unable to verify '$ENTRY'"
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

