#!/bin/bash
# Clinton Webb, 2024
#
# This is used to verify that all hosts in an inventory are either in the site1 group or site2 group.  
# This is because the daily runs will seperate via site, to ensure that services are not impacted on both sites at the same time.


if [[ -z "$1" ]]; then
  echo "Require inventory file"
  echo "  eg, tools/check_site_hosts_total.sh inventory/awad05/dev/inventory"
  sleep 1
  exit 1
fi

if [[ ! -e $1 ]]; then
  echo "Inventory file does not exist"
  sleep 1
  exit 1
fi

ansible-inventory -i $1 --graph all|grep -v '@'|sed 's/  |//g'|sed 's/^--//g'|sort|uniq > check_all.txt
ansible-inventory -i $1 --graph site1|grep -v '@'|sed 's/  |//g'|sed 's/^--//g'|sort|uniq > check_site1.txt
ansible-inventory -i $1 --graph site2|grep -v '@'|sed 's/  |//g'|sed 's/^--//g'|sort|uniq > check_site2.txt
cat check_site1.txt check_site2.txt|sort > check_sites.txt
diff check_sites.txt check_all.txt
rm check_all.txt check_site1.txt check_site2.txt check_sites.txt


