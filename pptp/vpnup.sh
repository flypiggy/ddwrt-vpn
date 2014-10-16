#!/bin/sh

set -x
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"

LOG='/tmp/autoddvpn.log'
LOCK='/tmp/autoddvpn.lock'
PID=$$
GFWIPLIST='/jffs/gfwips.lst'
INFO="[INFO#${PID}]"
DEBUG="[DEBUG#${PID}]"
ERROR="[ERROR#${PID}]"

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup.sh started" >> $LOG
for i in 1 2 3 4 5 6
do
  if [ -f $LOCK ]; then
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") got $LOCK , sleep 10 secs. #$i/6" >> $LOG
    sleep 10
  else
    break
  fi
done

if [ -f $LOCK ]; then
   echo "$ERROR $(date "+%d/%b/%Y:%H:%M:%S") still got $LOCK , I'm aborted. Fix me." >> $LOG
   exit 0
fi
#else
# echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $LOCK was released, let's continue." >> $LOG
#fi

# create the lock
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup" >> $LOCK



OLDGW=$(nvram get wan_gateway)

case $1 in
  "pptp")
    case "$(nvram get router_name)" in
      "tomato")
        echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") router type: tomato" >> $LOG
        OLDGW=$(nvram get wan_gateway_get)
        VPNSRV=$(nvram get pptp_client_srvip)
        VPNSRVSUB=$(nvram get pptp_client_srvsubmsk)
        PPTPDEV=$(nvram get pptp_client_iface)
        VPNGW=$(nvram get pptp_client_srvsub)
        ;;
      *)
        # assume it to be a DD-WRT
        echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") router type: DD-WRT" >> $LOG
        VPNSRV=$(nvram get pptpd_client_srvip)
        VPNSRVSUB=$(nvram get pptpd_client_srvsub)
        PPTPDEV=$(route -n | grep ^${VPNSRVSUB%.[0-9]*} | awk '{print $NF}' | head -n 1)
        VPNGW=$(ifconfig $PPTPDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
        VPNUPCUSTOM='/jffs/pptp/vpnup_custom'
        ;;
    esac
    ;;
  "openvpn")
    VPNSRV=$(nvram get openvpncl_remoteip)
    #OPENVPNSRVSUB=$(nvram get OPENVPNd_client_srvsub)
    #OPENVPNDEV=$(route | grep ^$OPENVPNSRVSUB | awk '{print $NF}')
    OPENVPNDEV='tun0'
    VPNGW=$(ifconfig $OPENVPNDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
    VPNUPCUSTOM='/jffs/openvpn/vpnup_custom'
    ;;
  *)
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") unknown vpnup.sh parameter,quit." >> $LOCK
    exit 1
esac



if [ $OLDGW == '' ]; then
  echo "$ERROR OLDGW is empty, is the WAN disconnected?" >> $LOG
  exit 0
else
  echo "$INFO OLDGW is $OLDGW"
fi

# use white list vpn so don't need this
# route add -host $VPNSRV gw $OLDGW
# echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") delete default gw $OLDGW"  >> $LOG
# route del default gw $OLDGW
#
# echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") add default gw $VPNGW"  >> $LOG
# route add default gw $VPNGW


echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") adding the static routes, this may take a while." >> $LOG

#check gfwlist
if [ ! -f $GFWIPLIST ]; then
  echo "$ERROR $(date "+%d/%b/%Y:%H:%M:%S") fail to fetch $GFWIPLIST, please fetch it manually."  >> $LOG
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup.sh ended" >> $LOG
  # release the lock
  rm -f $LOCK
  exit 0
fi

# add gfw routes
for i in $(grep -v ^# $GFWIPLIST)
do
  # check the item is a subnet or a single ip address
  echo $i | grep "/" > /dev/null
  if [ $? -eq 0 ]; then
    route add -net $i gw $VPNGW
  else
    route add $i gw $VPNGW
  fi
done

# final check again
echo "$INFO final check the default gw"
while true
do
  GW=$(route -n | grep ^0.0.0.0 | awk '{print $2}')
  echo "$DEBUG my current gw is $GW"
  #route | grep ^default | awk '{print $2}'
  if [ "$GW" == "$OLDGW" ]; then
    echo "$DEBUG GOOD"
    #echo "$INFO delete default gw $OLDGW"
    #route del default gw $OLDGW
    #echo "$INFO add default gw $VPNGW again"
    #route add default gw $VPNGW
    break
  else
    echo "$DEBUG default gw is not WAN GW"
    break
  fi
done

echo "$INFO static routes added"
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup.sh ended" >> $LOG
# release the lock
rm -f $LOCK
