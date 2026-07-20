#!/bin/bash
# Clinton Webb - 2024

# This script will be executed automatically every evening

#zInventories=("dev" "test" "infra" "uwca" "pwca" "dmz")
#zInventories=("dev" "test" "uwca" "pwca" "dmz")
#zInventories=("dev" "test" "uwca" "pwca" "dmz")
#zInventories=("dev" "test")
zInventories=("dev")

declare -A zInvDir
zInvDir["dev"]="awad05/dev"
zInvDir["test"]="awad05/test"
zInvDir["infra"]="awad05/infra"
zInvDir["uwca"]="uwca"
zInvDir["pwca"]="pwca"
zInvDir["dmz"]="dmz"

declare -A zInvBranch
zInvBranch["dev"]="development"
zInvBranch["test"]="test"
zInvBranch["infra"]="production"
zInvBranch["uwca"]="uat"
zInvBranch["pwca"]="production"
zInvBranch["dmz"]="production"

DDATE=$(date +%F)

# If no parameter is specified (indicating inventory), it will go through the list and make the calls (with the inventory as the parameter)
# The reason for this is that the actual run will use the script in the appropriate environment branch.
# This can be debated, as it could actually be better to always run on the 'developer' branch version 
# (which is what the initial trigger run will always point to).
if [[ -z "$1" ]]; then

  for INV in ${zInventories[@]}; do
    tDIR=${zInvDir["$INV"]}
    tBranch=${zInvBranch["$INV"]}

    echo "Inventory: $INV"
    echo "Dir: $tDIR"
    echo "Branch: $tBranch"
    echo

    if pushd $HOME/deploy/$tBranch; then
      git checkout $tBranch
      git pull origin $tBranch

      if [[ -x $HOME/deploy/$tBranch/tools/nightly.sh ]]; then
        $HOME/deploy/$tBranch/tools/nightly.sh $INV
      else
        echo "FAILED"
        sleep 2
        exit 1
      fi
      popd
    fi
  done
else
  INV="$1"
  tDIR=${zInvDir["$INV"]}
  tBranch=${zInvBranch["$INV"]}

  if pushd $HOME/deploy/$tBranch; then

    test -d $HOME/logs/$tBranch || mkdir $_

    for SITE in site1 site2; do
      DLOG="$HOME/logs/$tBranch/$INV-$SITE-$DDATE.log"

      # Rotate any existing log-files
      OLDII=99
      test -e $DLOG.99 && rm $_
      for II in `seq -w 98|tac`; do
        test -e $DLOG.$II && mv $DLOG.$II $DLOG.$OLDII
        OLDII=$II
      done
      test -e $DLOG && mv $DLOG $DLOG.01

      touch $DLOG
      echo "Started: `date`" | tee -a $DLOG
      echo "Checking inventory" | tee -a $DLOG
      if [[ -x tools/check_site_hosts_total.sh ]]; then
        tools/check_site_hosts_total.sh inventory/$tDIR | tee -a $DLOG
      fi
      echo "Skipped Hosts: " | tee -a $DLOG
      2>&1 ansible -i inventory/$tDIR --list-hosts skip_nightly |
        grep -v 'Could not match supplied host pattern' |
        grep -v 'No hosts matched, nothing to do' |
        tee -a $DLOG
      echo "Deploying to $SITE" | tee -a $DLOG
      echo "Verify connectivity" | tee -a $DLOG
      ansible -i inventory/$tDIR -m ping all|grep ' => {'| tee -a $DLOG
      echo | tee -a $DLOG
      ansible-playbook -i inventory/$tDIR --limit=$SITE,!skip_nightly --diff playbooks/base.yaml | tee -a $DLOG

      echo "$INV-$SITE" > $DLOG.summary
      grep -E '^PLAY RECAP' -A 500000 $DLOG >> $DLOG.summary
      grep 'unreachable=' $DLOG.summary | grep -v 'failed=0' > $DLOG.failed
      grep 'unreachable=' $DLOG.summary | grep -v 'changed=0' > $DLOG.changed

      echo "Finished: `date`" | tee -a $DLOG
      echo "Mintues: $(( SECONDS/60 ))"

#      sleep 1
    done
    popd
  fi
fi

