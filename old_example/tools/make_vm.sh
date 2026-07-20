#!/bin/bash
# Create VM from Template.
# Clinton Webb 2024
# Inspired by Dinesh Balendran

OPT_TEMPLATES=(RHEL8 RHEL9)
OPT_VMHOSTS=(vcn vcp1 vcp2)
OPT_CLUSTERS=(Cluster1 Cluster2 Oracle1 Oracle2)
OPT_CPUS=(1 2 4 8 16)
OPT_RAMS=(2048 4096 8192 16384 32768 65536 131072)

declare -A VMHOSTS
VMHOSTS["vcn"]="vcn2-1.mgt.internal.ausiex.com"
VMHOSTS["vcp1"]="vcp1-2.mgt.internal.ausiex.com"
VMHOSTS["vcp2"]="vcp2-2.mgt.internal.ausiex.com"

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
  echo ' --template "VM Template" ex:[RHEL8,RHEL9]'
  echo ' --vmname "VM Name"'
  echo ' --hostname "VM Hostsname"'
  echo ' --ip "VM IP"'
  echo ' --network "Network VLAN"'
  echo ' --vmhost "VMHost" ex:[vcn,vcp1,vcp2]'
  echo ' --cluster "Cluster Name" ex:[Cluster1,Oracle1]'
  echo ' --folder "Folder Name" ex:[Environment/Dev]'
  echo ' --cpu "CPU Count" ex[4]'
  echo ' --ram|--memory "RAM Amount (in MB)" ex:[8192,16384,32768]'
  echo ' --disk|--thin "Disk Size (in GB)" ex:[100,200]'
  echo ' --thick "Disk Size (in GB)" ex:[100,200]'
  echo ' --extra "config_file"'
  echo ' --yes'
  echo
  echo "Conditions:"
  echo " - If 'hostname' is not specified but 'vmname' is, then it will use 'vmname'"
  echo " - If 'vmname' is not specified but 'hostname' is, then it will use 'hostname'"
  echo " - If 'extra' is set, it will include additonal config file content into the main.tf config"
  echo " - If 'yes' is set, it will not ask for confirmation..."
  echo " - If 'yes' is set, it needs to be the very last parameter on the command."

  exit 1
fi

#VM_TEMPLATE=$(verify ${VV_TEMPLATE:-none} "Template:" "Which Template?" ${OPT_TEMPLATES[@]}) || exit 1
function verify() {

  local NW=n
  local SORTTOOL=cat
  local DEF=
  if [[ "$1" == '-d' ]]; then DEF=$2; shift; shift; fi
  if [[ "$1" == '-nw' ]]; then NW=y; shift; fi
  if [[ "$1" == '-sort' ]]; then SORTTOOL=sort; shift; fi

  local ORIG=$1
  local HEADER=$2
  local Q=$3
  local OUTP=

  # Combine all the extra parameters into an array (to make it easier to check the entry matches)
  local LIST=("${@:4}")

  [[ $ORIG != 'none' ]] && OUTP=$ORIG

  local GOFORIT=n
  while [[ $GOFORIT != [yY] ]]; do

    while [[ -z "$OUTP" ]] && [[ "$ORIG" == 'none' ]] ; do
      >&2 echo
      >&2 echo "$HEADER"
      for II in ${LIST[@]}; do
        echo " - $II"
      done | $SORTTOOL >&2
      >&2 read -p "$Q : " OUTP
      [[ -z $OUTP ]] && [[ -n $DEF ]] && OUTP=$DEF
    done

    # If this interaction has been tagged as a Network one, to make things easier in the interface,
    # we can take the shortened version (like '014') and lookup the real network (which is '014_DEV')
    if [[ "$NW" == "y" ]]; then
      local NWT=${OPT_NWS[$OUTP]}
      [[ -n $NWT ]] && OUTP=$NWT
    fi

    # Now compare the entry with the list provided.
    if [[ ! " ${LIST[*]} " =~ [[:space:]]${OUTP}[[:space:]] ]]; then
      >&2 read -p "'$OUTP' is not in the list.  Are you sure you want to use it (y/n)? " -n 1 GOFORIT
      >&2 echo
      if [[ ! $GOFORIT == [yY] ]]; then
        OUTP=
        ORIG=none
      fi
    else
      GOFORIT=y
    fi

  done
  echo "$OUTP"
}

function nextvar() {
  if [[ -n $2 ]] && [[ ${2:0:1} != '-' ]]; then
    echo "$2"
  else
    echo "Invalid Parameter: $1" 1>&2
    sleep 1
  fi
}

declare -a VV_DISKS
declare -a VV_THICK_DISKS

while [[ -n $1 ]]; do

  # If the paramters are done like --hostname="fred" then we want to handle that.
  # We also want to handle it if they done like --hostname fred.
  if [[ $1 == *=* ]]; then
    IFS='='; TT=($1); unset IFS;
    ONE=${TT[0]}
    TWO=${TT[1]}
  else
    ONE=$1
    TWO=$2
    shift
  fi

  case $ONE in
    --template)       VV_TEMPLATE=$(nextvar $ONE $TWO) || exit $? ;;
    --vmname)         VV_VMNAME=$(nextvar $ONE $TWO) || exit $? ;;
    --hostname)       VV_HOSTNAME=$(nextvar $ONE $TWO) || exit $? ;;
    --ip)             VV_IP=$(nextvar $ONE $TWO) || exit $? ;;
    --network)        VV_NETWORK=$(nextvar $ONE $TWO) || exit $? ;;
    --vmhost)         VV_VMHOST=$(nextvar $ONE $TWO) || exit $? ;;
    --cluster)        VV_CLUSTER=$(nextvar $ONE $TWO) || exit $? ;;
    --folder)         VV_FOLDER=$(nextvar $ONE $TWO) || exit $? ;;
    --cpu)            VV_CPU=$(nextvar $ONE $TWO) || exit $? ;;
    --ram|--memory)   VV_MEMORY=$(nextvar $ONE $TWO) || exit $? ;;
    --disk|--thin)    VV_DISKS+=($(nextvar $ONE $TWO)) || exit $? ;;
    --thick)          VV_THICK_DISKS+=($(nextvar $ONE $TWO)) || exit $? ;;
    --extra|--config) VV_EXTRA=$(nextvar $ONE $TWO) || exit $? ;;
    --yes)            VV_YES=y ;;

    *)
      echo "Unknown Parameter: $1"
      echo "Exiting."
      sleep 1
      exit 1
      ;;
  esac
  shift
done

if [[ -n $VV_EXTRA ]]; then
  if [[ ! -e $VV_EXTRA ]]; then
    echo "Extra Config File: $VV_EXTRA"
    echo "Does not exist!."
    sleep 2
    exit 1
  else
    VV_EXTRA=$(realpath $VV_EXTRA)
  fi
fi

VV_TEMPLATE=$(verify -sort ${VV_TEMPLATE:-none} "Templates:" "Which Template?" ${OPT_TEMPLATES[@]})
VV_VMHOST=$(verify -sort ${VV_VMHOST:-none} "VM Host Environments:" "Which VM Environment?" ${OPT_VMHOSTS[@]})
VV_CLUSTER=$(verify ${VV_CLUSTER:-none} "Clusters:" "Which Cluster?" ${OPT_CLUSTERS[@]})

declare -A OPT_NWS
case $VV_VMHOST in
  vcn)
    DEF_FOLDER=
    case $VV_CLUSTER in
      Cluster1)
        OPT_NWS['002']=002_INTERNAL_SERVER
        OPT_NWS['012']=012_DEV_MANAGEMENT
        OPT_NWS['014']=014_DEV
        OPT_NWS['015']=015_TEST
        OPT_NWS['025']=025_CTXAPP_DEV
        OPT_NWS['026']=026_CTXWEB_DEV
        OPT_NWS['027']=027_CTXDB_DEV
        OPT_NWS['028']=028_CTXAPP_TEST
        OPT_NWS['029']=029_CTXWEB_TEST
        OPT_NWS['030']=030_CTXDB_TEST
        OPT_NWS['053']=053_VMWARE_S1
        OPT_NWS['072']=072_DMZ_DEV_S1
        OPT_NWS['073']=073_DMZ_TEST_S1
        OPT_NWS['205']=205_IPNET_DEV
        OPT_NWS['211']=211_INFRA
        OPT_NWS['212']=212_CYBER_TOOLS_NP
        OPT_NWS['213']=213_INFRA_BUILD
        OPT_NWS['222']=222_INFRA_TOOLS
        OPT_NWS['227']=227_ExaData_Management
        OPT_NWS['229']=229_ExaData_Backup
        OPT_NWS['383']=383_TSM_BACKUP
        OPT_NWS['653']=653_VMWARE_S2
        ;;

      Cluster2)
        OPT_NWS['002']=002_INTERNAL_SERVER
        OPT_NWS['012']=012_DEV_MANAGEMENT
        OPT_NWS['014']=014_DEV
        OPT_NWS['015']=015_TEST
        OPT_NWS['025']=025_CTXAPP_DEV
        OPT_NWS['026']=026_CTXWEB_DEV
        OPT_NWS['027']=027_CTXDB_DEV
        OPT_NWS['028']=028_CTXAPP_TEST
        OPT_NWS['029']=029_CTXWEB_TEST
        OPT_NWS['030']=030_CTXDB_TEST
        OPT_NWS['205']=205_IPNET_DEV
        OPT_NWS['211']=211_INFRA
        OPT_NWS['212']=212_CYBER_TOOLS_NP
        OPT_NWS['213']=213_INFRA_BUILD
        OPT_NWS['653']=653_VMWARE_S2
        OPT_NWS['672']=672_DMZ_DEV_S2
        OPT_NWS['673']=673_DMZ_TEST_S2
        ;;
      *)
        echo "'$VV_VMHOST' does not have '$VV_CLUSTER' cluster."
        echo "Exiting"
        sleep 1
        exit 1
        ;;
    esac
    ;;
  vcp1)
    DEF_FOLDER=$VV_CLUSTER
    case $VV_CLUSTER in
      Cluster1)
        OPT_NWS['002']=002_INTERNAL_SERVER
        OPT_NWS['013']=013_AUSFW_DMZ
        OPT_NWS['016']=016_INTERNAL_TRANSFER
        OPT_NWS['017']=017_INTERNAL_TRANSFER_UAT
        OPT_NWS['018']=018_OFFICE_SERVER
        OPT_NWS['019']=019_OFFICE_TERMINAL
        OPT_NWS['021']=021_PORTFOLIO_APP_UAT
        OPT_NWS['031']=031_PORTFOLIO_APP
        OPT_NWS['032']=032_ELASTIC_AGENT
        OPT_NWS['033']=033_ELASTIC_LOGSTASH
        OPT_NWS['034']=034_ELASTIC_PROXY
        OPT_NWS['044']=044_MANAGEMENT_S1
        OPT_NWS['046']=046_SECURITY_S1
        OPT_NWS['050']=050_LEGACY_DMZ_S1
        OPT_NWS['053']=053_VMWARE_S1
        OPT_NWS['056']=056_DMZ_S1
        OPT_NWS['071']=071_NETWORK_SECURITY_S1
        OPT_NWS['074']=074_DMZ_UAT_S1
        OPT_NWS['099']=099_COMNEWS_S1
        OPT_NWS['107']=107_JDV_WEB
        OPT_NWS['221']=221_INFRA
        OPT_NWS['222']=222_INFRA_TOOLS
        OPT_NWS['223']=223_INFRA_BUILD
        OPT_NWS['224']=224_INFRA_DB
        OPT_NWS['226']=226_MONITORING
        OPT_NWS['228']=228_PLATO_DB
        OPT_NWS['231']=231_CYBER_TOOLS
        OPT_NWS['232']=232_CYMULATE_HOST
        OPT_NWS['242']=242_INTERNAL_APPS
        OPT_NWS['243']=243_INTERNAL_DB
        OPT_NWS['244']=244_DS_SERVICES
        OPT_NWS['293']=293_CORETX_DB_REPLICATION
        OPT_NWS['332']=332_AUSWEB_HOSTNET_S1
        OPT_NWS['334']=334_AUSWEB_SERVICENET_S1
        OPT_NWS['335']=335_AUSWEB_HOSTNET_S2
        OPT_NWS['337']=337_AUSWEB_SERVICENET_S2
        OPT_NWS['338']=338_AUSSHYWEB_S1
        OPT_NWS['340']=340_AUSSHYWEB_S2
        OPT_NWS['348']=348_AUSAPP_HOSTNET
        OPT_NWS['350']=350_AUSAPP_SERVICENET
        OPT_NWS['352']=352_AUSSHYFORMS
        OPT_NWS['353']=353_AUSINSIGHT
        OPT_NWS['354']=354_AUSSHYAPP
        OPT_NWS['363']=363_BROKER_APP
        OPT_NWS['364']=364_BROKER_DB
        OPT_NWS['366']=366_AUSDB
        OPT_NWS['368']=368_SHYDB
        OPT_NWS['380']=380_AUSWEB_MGT
        OPT_NWS['381']=381_AUSAPP_MGT
        OPT_NWS['382']=382_MANAGEMENT
        OPT_NWS['383']=383_BACKUP
        OPT_NWS['450']=450_AUSWEB_HOSTNET_UAT_S1
        OPT_NWS['452']=452_AUSWEB_SERVICENET_UAT_S1
        OPT_NWS['454']=454_AUSSHYWEB_UAT_S1
        OPT_NWS['460']=460_AUSWEB_HOSTNET_UAT_S2
        OPT_NWS['462']=462_AUSWEB_SERVICENET_UAT_S2
        OPT_NWS['464']=464_AUSSHYWEB_UAT_S2
        OPT_NWS['465']=465_AUSAPP_HOSTNET_UAT
        OPT_NWS['467']=467_AUSAPP_SERVICENET_UAT
        OPT_NWS['470']=470_AUSSHYAPP_UAT
        OPT_NWS['472']=472_AUSSHYFORMS_UAT
        OPT_NWS['473']=473_INSIGHT_UAT
        OPT_NWS['475']=475_BROKER_APP_UAT
        OPT_NWS['476']=476_BROKER_DB_UAT
        OPT_NWS['478']=478_AUSDB_UAT
        OPT_NWS['479']=479_SHYDB_UAT
        OPT_NWS['484']=484_AUSWEB_MGT_UAT
        OPT_NWS['485']=485_AUSAPP_MGT_UAT
        OPT_NWS['491']=491_CORETX_DB_REPLICATION_UAT
        OPT_NWS['646']=646_SECURITY_S2
        OPT_NWS['650']=650_LEGACY_DMZ_S2
        OPT_NWS['653']=653_VMWARE_S2
        OPT_NWS['683']=683_HARAPP
        OPT_NWS['699']=699_COMNEWS_S2
        OPT_NWS['751']=751_IPNET_PROD
        ;;
      Oracle1)
        OPT_NWS['012']=012_DEVMGT_ORA
        OPT_NWS['014']=014_DEV_ORA
        OPT_NWS['015']=015_TEST_ORA
        OPT_NWS['021']=021_PORTFOLIO_APP_UAT_ORA
        OPT_NWS['031']=031_PORTFOLIO_APP_ORA
        OPT_NWS['053']=053_VMWARE_S1_ORA
        OPT_NWS['223']=223_INFRA_BUILD_ORA
        OPT_NWS['228']=228_ARCHIVE_ORA
        OPT_NWS['352']=352_AUSSHYFORMS_ORA
        OPT_NWS['363']=363_BROKER_APP_ORA
        OPT_NWS['364']=364_BROKER_DB_ORA
        OPT_NWS['365']=365_SHYDB_ARCHIVE_ORA
        OPT_NWS['368']=368_SHYDB_ORA
        OPT_NWS['384']=384_MANAGEMENT_DB_ORA
        OPT_NWS['472']=472_AUSSHYFORMS_UAT_ORA
        OPT_NWS['475']=475_BROKER_APP_UAT_ORA
        OPT_NWS['476']=476_BROKER_DB_UAT_ORA
        OPT_NWS['477']=477_SHYDB_UAT_ARCHIVE_ORA
        OPT_NWS['479']=479_SHYDB_UAT_ORA
        OPT_NWS['636']=636_POCDB_UAT_ORA
        OPT_NWS['750']=750_IPNET_DEV_ORA
        ;;
      *)
        echo "'$VV_VMHOST' does not have '$VV_CLUSTER' cluster."
        echo "Exiting"
        sleep 1
        exit 1
        ;;
    esac
    ;;
  vcp2)
    DEF_FOLDER=$VV_CLUSTER
    case $VV_CLUSTER in
      Cluster2)
        OPT_NWS['002']=002_INTERNAL_SERVER
        OPT_NWS['013']=013_AUSFW_DMZ
        OPT_NWS['016']=016_INTERNAL_TRANSFER
        OPT_NWS['017']=017_INTERNAL_TRANSFER_UAT
        OPT_NWS['018']=018_OFFICE_SERVER
        OPT_NWS['019']=019_OFFICE_TERMINAL
        OPT_NWS['021']=021_PORTFOLIO_APP_UAT
        OPT_NWS['031']=031_PORTFOLIO_APP
        OPT_NWS['046']=046_SECURITY_S1
        OPT_NWS['050']=050_LEGACY_DMZ_S2
        OPT_NWS['053']=053_VMWARE_S1
        OPT_NWS['099']=099_COMNEWS_S1
        OPT_NWS['221']=221_INFRA
        OPT_NWS['222']=222_INFRA_TOOLS
        OPT_NWS['223']=223_INFRA_BUILD
        OPT_NWS['224']=224_INFRA_DB
        OPT_NWS['226']=226_MONITORING
        OPT_NWS['228']=228_PLATO_DB
        OPT_NWS['231']=231_CYBER_TOOLS
        OPT_NWS['232']=232_CYMULATE_HOST
        OPT_NWS['242']=242_INTERNAL_APPS
        OPT_NWS['243']=243_INTERNAL_DB
        OPT_NWS['244']=244_DS_SERVICES
        OPT_NWS['293']=293_CORETX_DB_REPLICATION
        OPT_NWS['334']=334_AUSWEB_SERVICENET_S1
        OPT_NWS['335']=335_AUSWEB_HOSTNET_S2
        OPT_NWS['337']=337_AUSWEB_SERVICENET_S2
        OPT_NWS['338']=338_AUSSHYWEB_S1
        OPT_NWS['340']=340_AUSSHYWEB_S2
        OPT_NWS['348']=348_AUSAPP_HOSTNET
        OPT_NWS['350']=350_AUSAPP_SERVICENET
        OPT_NWS['352']=352_AUSSHYFORMS
        OPT_NWS['353']=353_AUSINSIGHT
        OPT_NWS['354']=354_AUSSHYAPP
        OPT_NWS['363']=363_BROKER_APP
        OPT_NWS['364']=364_BROKER_DB
        OPT_NWS['366']=366_AUSDB
        OPT_NWS['368']=368_SHYDB
        OPT_NWS['380']=380_AUSWEB_MGT
        OPT_NWS['381']=381_AUSAPP_MGT
        OPT_NWS['382']=382_MANAGEMENT
        OPT_NWS['383']=383_BACKUP
        OPT_NWS['450']=450_AUSWEB_HOSTNET_UAT_S1
        OPT_NWS['452']=452_AUSWEB_SERVICENET_UAT_S1
        OPT_NWS['454']=454_AUSSHYWEB_UAT_S1
        OPT_NWS['460']=460_AUSWEB_HOSTNET_UAT_S2
        OPT_NWS['462']=462_AUSWEB_SERVICENET_UAT_S2
        OPT_NWS['464']=464_AUSSHYWEB_UAT_S2
        OPT_NWS['465']=465_AUSAPP_HOSTNET_UAT
        OPT_NWS['467']=467_AUSAPP_SERVICENET_UAT
        OPT_NWS['470']=470_AUSSHYAPP_UAT
        OPT_NWS['472']=472_AUSSHYFORMS_UAT
        OPT_NWS['473']=473_INSIGHT_UAT
        OPT_NWS['475']=475_BROKER_APP_UAT
        OPT_NWS['476']=476_BROKER_DB_UAT
        OPT_NWS['478']=478_AUSDB_UAT
        OPT_NWS['479']=479_SHYDB_UAT
        OPT_NWS['484']=484_AUSWEB_MGT_UAT
        OPT_NWS['485']=485_AUSAPP_MGT_UAT
        OPT_NWS['491']=491_CORETX_DB_REPLICATION_UAT
        OPT_NWS['644']=644_MANAGEMENT_S2
        OPT_NWS['646']=646_SECURITY_S2
        OPT_NWS['650']=650_LEGACY_DMZ_S2
        OPT_NWS['653']=653_VMWARE_S2
        OPT_NWS['656']=656_DMZ_S2
        OPT_NWS['671']=671_NETWORK_SECURITY_S2
        OPT_NWS['674']=674_DMZ_UAT_S2
        OPT_NWS['683']=683_HARAPP
        OPT_NWS['699']=699_COMNEWS_S2
        OPT_NWS['751']=751_IPNET_PROD
        ;;
      Oracle2)
        OPT_NWS['012']=012_MANAGEMENT_DEV_ORA
        OPT_NWS['014']=014_DEV_ORA
        OPT_NWS['015']=015_TEST_ORA
        OPT_NWS['021']=021_PORTFOLIO_APP_UAT_ORA
        OPT_NWS['031']=031_PORTFOLIO_APP_ORA
        OPT_NWS['223']=223_INFRA_BUILD_ORA
        OPT_NWS['228']=228_ARCHIVE_ORA
        OPT_NWS['351']=352_AUSSHYFORMS_ORA
        OPT_NWS['363']=363_BROKER_APP_ORA
        OPT_NWS['364']=364_BROKER_DB_ORA
        OPT_NWS['365']=365_SHYDB_ARCHIVE_ORA
        OPT_NWS['368']=368_SHYDB_ORA
        OPT_NWS['384']=384_MANAGEMENT_DB_ORA
        OPT_NWS['472']=472_AUSSHYFORMS_UAT_ORA
        OPT_NWS['475']=475_BROKER_APP_UAT_ORA
        OPT_NWS['476']=476_BROKER_DB_UAT_ORA
        OPT_NWS['477']=477_SHYDB_UAT_ARCHIVE_ORA
        OPT_NWS['479']=479_SHYDB_UAT_ORA
        OPT_NWS['636']=636_POCDB_UAT_ORA
        OPT_NWS['653']=653_VMWARE_S2_ORA
        OPT_NWS['750']=750_IPNET_DEV_ORA
        ;;
      *)
        echo "'$VV_VMHOST' does not have '$VV_CLUSTER' cluster."
        echo "Exiting"
        sleep 1
        exit 1
        ;;
    esac
    ;;
  *)
      echo "Unknown networks for this host: $VV_VMHOST" 
      sleep 1
      exit 1
    ;;
esac


VV_NETWORK=$(verify -nw -sort ${VV_NETWORK:-none} "Networks (VLAN's):" "Which Network? (Can just enter the number part)" ${OPT_NWS[@]})

[[ -z $VV_HOSTNAME ]] && read -p "The Hostname? : " VV_HOSTNAME
[[ -z $VV_VMNAME ]]   && read -p "The VM name? (Press Enter for '$VV_HOSTNAME' if same as Hostname) : " VV_VMNAME
[[ -z $VV_HOSTNAME ]] && [[ -n "$VV_VMNAME" ]] && VV_HOSTNAME=$VV_VMNAME
[[ -z $VV_VMNAME ]]   && [[ -n "$VV_HOSTNAME" ]] && VV_VMNAME=$VV_HOSTNAME
[[ -z $VV_VMNAME ]]   && echo "Need a VM name!!" && sleep 1 && exit 1

[[ -z $VV_IP ]] && read -p "The IP? (If none is provided, will have to be configured manually on the host) : " VV_IP
[[ -z $VV_FOLDER ]] && read -p "The Folder? (Press Enter for '$DEF_FOLDER') : " VV_FOLDER
[[ -z $VV_FOLDER ]] && VV_FOLDER=$DEF_FOLDER

VV_CPU=$(verify -d 2 ${VV_CPU:-none} "CPU's:" "How Many vCPU's? (Press Enter for '2')" ${OPT_CPUS[@]})
VV_MEMORY=$(verify -d 8192 ${VV_MEMORY:-none} "Common RAM Amounts:" "How much RAM in MB? (Press Enter for '8192')" ${OPT_RAMS[@]})



echo
echo "-------------------------------------------------------------"
echo "The VM will be created with the following information:"
echo
echo "  VM Name:      $VV_VMNAME"
echo "  Template:     $VV_TEMPLATE"
echo "  VM Env:       $VV_VMHOST"
echo "  Cluster:      $VV_CLUSTER"
echo "  Folder:       $VV_FOLDER"
echo "  Hostname:     $VV_HOSTNAME"
echo "  IP:           $VV_IP"
echo "  Network:      $VV_NETWORK"
echo "  CPU's:        $VV_CPU"
echo "  RAM (MB):     $VV_MEMORY"
echo "  Thin Disks:   ${VV_DISKS[@]}"
echo "  Thick Disks:  ${VV_THICK_DISKS[@]}"
echo "  Extra Config: $VV_EXTRA"
echo "-------------------------------------------------------------"
echo

while [[ $VV_YES != [yYnN] ]]; do
  read -p "Verify the details above.  Are you sure you want to create this VM? (y/n)? " -n 1 VV_YES
  echo
done

if [[ "$VV_YES" == [yY] ]]; then
  # Creating all the terraform configuration

  echo
  echo "Creating Terraform Config"

  mkdir .terraform.$$
  pushd .terraform.$$ || exit 1

  echo
  echo "Require VMWARE Credentials"
  while [[ -z $VM_USER ]]; do read -p "Login Username: " VM_USER; done
  while [[ -z $VM_PASS ]]; do read -s -p "Login Password: " VM_PASS; echo; done

  case $VV_CLUSTER in
    Cluster1|Oracle1) VV_DC=DC1 ;;
    Cluster2|Oracle2) VV_DC=DC2 ;;
  esac

  case $VV_VMHOST in
    vcn)
      VV_DCT="DC2"
      case $VV_CLUSTER in
        Cluster1) VV_DS="purevsn101" ;;
        Cluster2) VV_DS="purevsn201" ;;
      esac
      ;;
    vcp1)
      VV_DCT="DC1"
      case $VV_CLUSTER in
        Cluster1) VV_DS="purevsp101" ;;
        Oracle1)  VV_DS="purevso101" ;;
      esac
      ;;
    vcp2)
      VV_DCT="DC2"
      case $VV_CLUSTER in
        Cluster2) VV_DS="purevsp201" ;;
        Oracle2)  VV_DS="purevso201" ;;
      esac
      ;;
  esac

  if [[ "$VV_TEMPLATE" == "RHEL8" ]]; then 
    VV_GUEST="rhel8_64Guest"
  else
    VV_GUEST="rhel9_64Guest"
  fi

  VV_FW=efi
  # Most of the templates use EFI, but one was setup using BIOS  (when that is corrected, this can be removed)
  if [[ "$VV_VMHOST" == "vcn" ]] && [[ "$VV_TEMPLATE" == "RHEL8" ]]; then
    VV_FW=bios
  fi

  # Get the Full Vsphere Host name
  VV_VMHOST_F=${VMHOSTS["$VV_VMHOST"]}

  # Create the config.
  cat >main.tf << EOF
# Configure the vSphere provider
provider "vsphere" {
  user           = "$VM_USER"
  password       = "$VM_PASS"
  vsphere_server = "$VV_VMHOST_F"
  allow_unverified_ssl = true
}
# Define data sources for the VM placement
data "vsphere_datacenter" "dc" {
  name = "$VV_DC"
}
data "vsphere_datastore" "datastore" {
  name          = "$VV_DS"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_compute_cluster" "cluster" {
  name          = "$VV_CLUSTER"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
  name          = "$VV_NETWORK"
  datacenter_id = data.vsphere_datacenter.dc.id
}
# Specified the DC that the template is on (only really matters for Non-Prod)
data "vsphere_datacenter" "dct" {
  name = "$VV_DCT"
}
data "vsphere_virtual_machine" "template" {
  name          = "$VV_TEMPLATE"
  datacenter_id = data.vsphere_datacenter.dct.id
}
# Create the virtual machine
resource "vsphere_virtual_machine" "vm" {
  name             = "$VV_VMNAME"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "$VV_FOLDER"

  num_cpus = $VV_CPU
  memory   = $VV_MEMORY
  guest_id = "$VV_GUEST"
  firmware = "$VV_FW"
  wait_for_guest_ip_timeout = "0"
  wait_for_guest_net_timeout = "0"
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
  }
  disk {
    label = "system"
    unit_number = 0
    size  = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = true
  }
  extra_config = {
    "guestinfo.srvname" = "$VV_HOSTNAME"
    "guestinfo.srvip"   = "$VV_IP"
  }
EOF

  DISKNO=1

  # Note that we didn't close the end of the block, as we may have additional config to add.
  if [[ ${#VV_DISKS[@]} -gt 0 ]]; then
    for AA in ${VV_DISKS[@]}; do
      for BB in $(IFS=','; echo $AA); do
        echo "  disk {" >> main.tf
        echo "    label = \"disk$DISKNO\" " >> main.tf
        echo "    unit_number = $DISKNO" >> main.tf
        echo "    size = $BB " >> main.tf
        echo "    thin_provisioned = true" >> main.tf
        echo "  }" >> main.tf
        DISKNO=$((DISKNO + 1))
      done
    done
  fi

  if [[ ${#VV_THICK_DISKS[@]} -gt 0 ]]; then
    for AA in ${VV_THICK_DISKS[@]}; do
      for BB in $(IFS=','; echo $AA); do
        echo "  disk {" >> main.tf
        echo "    label = \"disk$DISKNO\" " >> main.tf
        echo "    unit_number = $DISKNO" >> main.tf
        echo "    size = $BB " >> main.tf
        echo "    thin_provisioned = false" >> main.tf
        echo "  }" >> main.tf
        DISKNO=$((DISKNO + 1))
      done
    done
  fi

  if [[ -n "$VV_EXTRA" ]] && [[ -e $VV_EXTRA ]]; then
    echo "Adding Exrtra config"
    cat $VV_EXTRA >> main.tf
  fi

  echo "}" >> main.tf

  https_proxy=http://proxy:3128 /opt/terraform/terraform init
  https_proxy= /opt/terraform/terraform plan -out=tfplan
  rm main.tf
  if [[ -e tfplan ]]; then
    https_proxy= /opt/terraform/terraform apply tfplan
    rm tfplan
  fi

  popd
  rm -rf .terraform.$$
fi
