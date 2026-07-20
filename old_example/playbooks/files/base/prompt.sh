#!/bin/bash

# Choose colors for environment

FQDN="`hostname -f`"
HOSTNAME="`hostname -s`"

if [[ "$SYSTEM_ENVIRONMENT" == '' ]]
then
  case "$HOSTNAME" in
    "i-"* )
      PROMPT_ENV_COLOR="\033[33m"
      SYSTEM_ENVIRONMENT='INFRA'
      ;;
    "p-"* )
      PROMPT_ENV_COLOR="\033[01;31m"
      SYSTEM_ENVIRONMENT='PROD'
      ;;
    "u-"* )
      PROMPT_ENV_COLOR="\033[35m"
      SYSTEM_ENVIRONMENT='UAT'
      ;;
    "t-"* | "t1-"* | "t2-"* )
      PROMPT_ENV_COLOR="\033[32m"
      SYSTEM_ENVIRONMENT='TEST'
      ;;
    "d-"* | "d1-"* | "d2-"* )
      PROMPT_ENV_COLOR="\033[32m"
      SYSTEM_ENVIRONMENT='DEV'
      ;;
    *)
      PROMPT_ENV_COLOR="\033[37m"
      SYSTEM_ENVIRONMENT='?'
      ;;
  esac
else
  case "$SYSTEM_ENVIRONMENT" in
    "PROD")
      PROMPT_ENV_COLOR="\033[01;31m"
      ;;
    "UAT")
      PROMPT_ENV_COLOR="\033[35m"
      ;;
    *)
      PROMPT_ENV_COLOR="\033[37m"
      ;;
  esac
fi

# Choose color for user@hostname

if [ "$USER" == 'root' ]; then
        PROMPT_USER_COLOR="\033[01;31m"
else
        PROMPT_USER_COLOR="\033[01;32m"
fi

# Only apply if $TERM is xterm, screen, or linux

case "$TERM" in
        xterm|screen|linux)
        export PS1="[\t \[$PROMPT_ENV_COLOR\]($SYSTEM_ENVIRONMENT) \[$PROMPT_USER_COLOR\]\u@\h \[\033[01;36m\]\W\[\033[00m\] ]\$ "
        ;;
esac

