#!/bin/bash
# Clinton Webb, 2024.
#
# Allow quick and simplified method to automatically create the PR's for each environment

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

gh auth status
if [[ $? -ne 0 ]]; then
  echo "You need to authenticate to Github for this to work"
  echo "See https://confluence.internal.ausiex.com/display/ITOPS/Github+CLI"
  sleep 1
  exit 1
else

  zBranches=("development" "test" "uat" "production")
  declare -A zShort
  zShort["development"]="DEV"
  zShort["test"]="TEST"
  zShort["uat"]="UAT"
  zShort["production"]="PROD"

  echo; echo
  TITLE=$1
  if [[ -z $TITLE ]]; then
    read -r -p "Title: " TITLE
  fi

  BODY=$2
  if [[ -z $BODY ]]; then
    read -p "Description: " BODY
  fi

  echo
  echo "----------------------------------------"
  echo "Title: $TITLE"
  echo "Description: $BODY"
  echo "----------------------------------------"
  echo
  echo "NOTE: Make sure you have committed all your changes into this current branch before submitting this!!"
  echo
  read -n 1 -p "Are you sure you want to submit this PR? (y/n)" YN; echo; echo

  case $YN in
    [yY] )

      git push origin $(parse_git_branch)
      if [[ $? -ne 0 ]]; then
        echo "Something wrong... investigate."
        sleep 2
        exit 1
      fi

      for BRANCH in ${zBranches[@]}; do
        SHORT=${zShort["$BRANCH"]}

        gh pr create --title "$TITLE ($SHORT)" --body "$BODY" --base $BRANCH --head $(parse_git_branch) --reviewer IT-Operations/it-sysadmin

      done
      ;;

    * ) echo "Ok... exiting."
        exit 1
      ;;

  esac
fi
