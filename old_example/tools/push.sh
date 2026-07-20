#!/bin/bash

#########
## NOTE
########
##   This is not a long-term process.   This is implemented while introducing functionality at a high pace while initial integration
##   Once most functionality has been implemented and stable, the push process will be disabled, and normal change-review process eganged.
########


if [[ -z "$1" ]]; then
  echo "usage:"
  echo "   $0 <branch> [branch list,...]"
  echo
  echo "example:"
  echo "   tools/push.sh feature_example"
  echo "      this will push the feature_example branch to all main branches (development, test, uat, production)"
  echo
  echo "example:"
  echo "   tools/push.sh feature_example development test"
  echo "      this will push the feature_example branch to just the development and test branches"
  echo
  sleep 1
  exit 1
fi

if [[ -z "$SSH_AGENT_PID" ]]; then
  echo "SSH Agent should be active"
  sleep 1
  exit 1
fi

CURR_BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

if [[ "$1" == "." ]]; then
  # If the branch is indicated as '.' then it will check the current branch.
  SRC_BRANCH=$CURR_BRANCH
else
  SRC_BRANCH=$1
fi

if [[ "$1" =~ ^(development|test|uat|production)$ ]]; then
  echo "Failed!  Shouldn't be pushing from the special branches"
  sleep 2
  exit 1
fi

TARGET_LIST="development test uat production"

# if specified, combine the extra targets into a single variable.
test -n "$2" && TARGET_LIST="${@:2}"
 
for II in $TARGET_LIST; do
  echo "$SRC_BRANCH -> $II"
  if [[ "$II" == "$SRC_BRANCH" ]]; then
    echo "Cannot merge '$II' into '$SRC_BRANCH'"
    sleep 2
  else
    git checkout $II && git pull origin $II && git merge $SRC_BRANCH -m "Merge branch '$SRC_BRANCH' into $II" && git push origin $II
    if [[ $? -ne 0 ]]; then
      echo "Failed."
      exit 2
    fi
  fi
done
git checkout $SRC_BRANCH

