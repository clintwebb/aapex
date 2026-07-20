#!/bin/bash

# Simple tool to vault some variables.
# Note that this is mostly for single-line entries... often passwods or secret tokens.

while true; do
  read -p 'Name: ' zNAME
  read -s -p 'Value: ' zVALUE
  echo;echo;
  echo "Vaulting: $zVALUE"
  echo;echo;

  ansible-vault encrypt_string --name=$zNAME "$zVALUE"
  echo
done
