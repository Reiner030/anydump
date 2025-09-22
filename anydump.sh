#!/usr/bin/env bash
#===================================================================================
#
# origin from: https://github.com/samson4649/anydump
#
# FILE: dump.sh
# USAGE: dump.sh [-i interface] [tcpdump-parameters]
# DESCRIPTION: tcpdump on any interface and add the prefix [Interace:xy] in front of the dump data.
# OPTIONS: same as tcpdump
# REQUIREMENTS: tcpdump, sed, ifconfig, kill, awk, grep, posix regex matching
# BUGS:  ---
# FIXED: - In 1.0 The parameter -w would not work without -i parameter as multiple tcpdumps are started.
#        - In 1.1 VLAN's would not be shown if a single interface was dumped.
# NOTES: ---
#        - 1.2 git initial
# AUTHOR: Sebastian Haas
# COMPANY: pharma mall
# VERSION: 1.2
# CREATED: 16.09.2014
# REVISION: 22.09.2014
#
#===================================================================================

# capture all interfaces
if tcpdump -D &>/dev/null 2>&1; then
	interfaces=( $(tcpdump -D | grep -v usb | sed -E 's/^[0-9]+\.([a-zA-Z0-9_]+).*/\1/' | tr '\n' ' ') )
elif which ip &>/dev/null 2>&1; then
	interfaces=( $(ip -br l | awk '{print $1}' | cut -d@ -f1 | sed ':a;N;$!ba;s/\n/ /g') )
elif which ifconfig &>/dev/null 2>&1; then
	interfaces=( $(ifconfig | grep '^[a-z0-9]' | awk '{print $1}' | cut -d: -f1 | sed ':a;N;$!ba;s/\n/ /g') )
else
	echo "Requires 'tcpdump -D' or 'ifconfig' or 'ip' to discover interfaces"
	exit 1
fi

# When this exits, exit all background processes:
trap 'kill $(jobs -p) &> /dev/null && sleep 0.2 &&  echo ' EXIT

# Create one tcpdump output per interface and add an identifier to the beginning of each line:
if [[ $@ =~ -i[[:space:]]?[^[:space:]]+ ]]; then
    tcpdump -l $@ | sed 's/^/[Interface:'"${BASH_REMATCH[0]:2}"'] /' &
else
	echo -n "Starting tcpdump onto interfaces:"
	for interface in ${interfaces[@]}; do
		#tcpdump -l -i $interface -nn $@ | sed 's/^/[Interface:'"$interface"']    /' &
		tcpdump -l -i $interface -nne $@ 2>/dev/null | sed -ne '/^$/d; s/^/[Interface:'"$interface"']    /p' &
		echo -n " $interface"
	done
	echo ":"
fi
# wait .. until CTRL+C
wait
