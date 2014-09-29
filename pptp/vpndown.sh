#!/bin/sh
# This script is modified by Shujenchang from http://autoddvpn.googlecode.com/svn/trunk/vpndown.sh
# Shujen & Park
# We're together forever!

set -x
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"


LOG='/tmp/autoddvpn.log'
LOCK='/tmp/autoddvpn.lock'
EXVPNROUTEDIR='/jffs/exvpnroute.d'
PID=$$
INFO="[INFO#${PID}]"
DEBUG="[DEBUG#${PID}]"
ERROR="[ERROR#${PID}]"

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpndown.sh started" >> $LOG
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
  #else
  #	echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $LOCK was released, let's continue." >> $LOG
fi

# create the lock
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup" >> $LOCK

OLDGW=$(nvram get wan_gateway)

case $1 in
  "pptp")
    PPTPSRV=$(nvram get pptpd_client_srvip)
    VPNGW=$(nvram get pptp_gw)
    ;;
  "openvpn")
    OPENVPNSRV=$(nvram get openvpncl_remoteip)
    OPENVPNDEV='tun0'
    VPNGW=$(ifconfig $OPENVPNDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
    ;;
  *)
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") unknown vpndown.sh parameter, quit." >> $LOCK
    exit 1
    ;;
esac

if [ $(nvram get gracevpn_enable) -eq 1 ]; then

  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") mode: grace mode"  >> $LOG

  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") removing the static routes" >> $LOG

  #route -n | awk '$2 ~ /192.168.172.254/{print $1,$3}'  | while read x y
  route -n | awk '$NF ~ /tun0/{print $1,$3}' | while read x y
do
  echo "deleting $x $y"
  route del -net $x netmask $y
done

else

  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") mode: classical mode"  >> $LOG

  #route del -host $PPTPSRV
  route del default gw $VPNGW
  echo "$INFO add $OLDGW back as the default gw"
  route add default gw $OLDGW

fi

# delete the exceptional VPN routes
if [ $(nvram get exvpnroute_enable) -eq 1 ]; then
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") deleting the exceptional VPN routes" >> $LOG
  for i in $(nvram get exvpnroute_list)
  do
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") fetching exceptional VPN routes for $i"  >> $LOG
    if [ ! -f $EXVPNROUTEDIR/$i ]; then
      echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $EXVPNROUTEDIR/$i not found, skip."  >> $LOG
      continue
    fi
    for r in $(grep -v ^# $EXVPNROUTEDIR/$i)
    do
      echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") deleting $r via VPN_gateway"  >> $LOG
      # check the item is a subnet or a single ip address
      echo $r | grep "/" > /dev/null
      if [ $? -eq 0 ]; then
        route del -net $r gw $VPNGW
      else
        route del $r gw $VPNGW
      fi
    done
  done
else
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") exceptional VPN routes disabled, skip."  >> $LOG
fi

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpndown.sh ended" >> $LOG

# release the lock
rm -f $LOCK
