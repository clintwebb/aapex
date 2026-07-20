#!/bin/bash
# This is generally only executed when the server is not already registered.

SATELLITE='i-rhsat2-2.mgt.internal.ausiex.com'
RELEASE="`cat /etc/redhat-release|cut -d '.' -f1|awk '{print $NF}'`"
HOST=`hostname -s | cut -d '.' -f 1`
ZONE=`hostname -f | cut -d '.' -f 2`
TEMP=`echo ${HOST: -4}|cut -d '-' -f 1`
SITE=${TEMP: -1}
if ! [[ "$SITE" =~ [1-2] ]]; then
  SITE=1
fi

case $ZONE in
  dev|dev1|dev2|dev3|dev4|dev5|nonprod)  KEY="dev${SITE}"   ;;
  test|test1|test2|test3|test4|test5)    KEY="test${SITE}"  ;;
  uwca|uwcw)                             KEY="uat${SITE}"   ;;
  pwca|pwcw)                             KEY="prod${SITE}"  ;;
  management|mgt|cas|prod|awad05)        KEY="infra${SITE}" ;;
  *)                                     KEY="infra${SITE}" ;;
esac

cd /tmp
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
sudo rm -f /etc/yum.repos.d/*.repo
sudo yum clean all && sudo rm -rf /var/cache/yum
sudo rm /etc/insights-client/machine-id
sudo subscription-manager unregister
sudo subscription-manager clean
sudo yum remove -y 'candlepin*' 'katello*' insights-client
sudo sed -i '/^proxy/d' /etc/yum.conf
sudo sed -i 's/^proxy/#proxy/' /etc/rhsm/rhsm.conf
sudo sed -i 's/^enableProxy\=1/enableProxy\=0/' /etc/sysconfig/rhn/up2date

KATELLO='katello-ca-consumer-latest.noarch.rpm'
curl --insecure -o $KATELLO https://${SATELLITE}/pub/$KATELLO
sudo rpm -Uvh $KATELLO
rm -f $KATELLO
sudo subscription-manager register --org="ausiex" --activationkey="$KEY"
if [[ $? -ne 0 ]]; then
  echo '-------------------------------------'
  echo '-------------------------------------'
  echo '  WARNING - RHSM REGISTER FAILED!!'
  echo '-------------------------------------'
  echo '-------------------------------------'
  exit 1
else
  sudo subscription-manager attach --auto
  # additional repositories handled in the ansible playbook directly.
fi

touch /etc/rhsm/.registered

exit 0
