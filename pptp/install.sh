#!/bin/sh
nvram set rc_startup="/jffs/pptp/run.sh"
nvram set dns_dnsmasq="1"
nvram set dhcp_dnsmasq="1"
nvram set dnsmasq_enable="1"
nvram set local_dns="1"
nvram set dnsmasq_no_dns_rebind="1"
nvram set dnsmasq_options="conf-file=/jffs/dnsmasq.conf"
nvram set router_name="DD-WRT"
nvram set pptpd_client_enable="1"
nvram set pptpd_client_srvsec="mppe required,no40,no56,stateless"
nvram set gracevpn_enable="1"
nvram commit
