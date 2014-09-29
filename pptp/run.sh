#!/bin/sh
# This script is modified by Shujenchang from http://autoddvpn.googlecode.com/svn/trunk/run.sh
# Shujen & Park
# We're together forever!

VPNUP='vpnup.sh'
VPNDOWN='vpndown.sh'
VPNLOG='/tmp/autoddvpn.log'
#PPTPSRVSUB=$(nvram get pptpd_client_srvsub)
#DLDIR='http://autoddvpn.googlecode.com/svn/trunk/'
#CRONJOBS="* * * * * root /bin/sh /tmp/check.sh >> /tmp/last_check.log"
PID=$$
INFO="[INFO#${PID}]"
ERROR="[ERROR#${PID}]"
DEBUG="[DEBUG#${PID}]"
IPUP="/tmp/pptpd_client/ip-up"
IPDOWN="/tmp/pptpd_client/ip-down"

if [ "$(nvram get pptpd_client_enable)" = "0" ]; then
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") PPTP not enabled, or using manual mode" >> $VPNLOG
  exit 0
fi

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") log starts" >> $VPNLOG
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") pptp+jffs mode" >> $VPNLOG

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") modifying $IPUP" >> $VPNLOG

for i in 1 2 3 4 5 6 7 8 9 10 11 12
do
  if [ -e $IPUP ]; then
    sed -ie 's#exit 0#/jffs/pptp/vpnup.sh pptp\nexit 0#g' $IPUP
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $IPUP modified" >> $VPNLOG
    break
  else
    echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $IPUP not exists, sleep 10sec." >> $VPNLOG
    sleep 10
  fi
done

if [ ! -e $IPUP ]; then
  echo "$ERROR $(date "+%d/%b/%Y:%H:%M:%S") $IPUP still not exists, something goes wrong." >> $VPNLOG
  exit 1
fi

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") modifying $IPDOWN" >> $VPNLOG
if [ -e $IPDOWN ]; then
  sed -ie 's#exit 0#/jffs/pptp/vpndown.sh pptp\nexit 0#g' $IPDOWN
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $IPDOWN modified" >> $VPNLOG
  echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") ALL DONE. Let's wait for VPN being connected." >> $VPNLOG
else
  echo "$ERROR $(date "+%d/%b/%Y:%H:%M:%S") $IPDOWN not exists, something goes wrong." >> $VPNLOG
fi
