#!/bin/bash

# source bash JSON parser
source /usr/local/lib/stdlib.sh
source $LIBDIR/ticktick.sh

DIR=$( dirname "$( readlink -f $0 )" )

while getopts ":h:d:" opt;
do
        case $opt in
                d) DHCP="$OPTARG" ;;
                h) HOSTS="$OPTARG" ;;
        esac
done

# Read in dhcp data and parse it
DATA=`cat $HOSTS`
tickParse "hostdata = $DATA"

DATA=`cat $DHCP`
tickParse "dhcpdata = $DATA"

# gather global data
global_domain_name=``dhcpdata.global.domain_name``;
global_default_lease_time=``dhcpdata.global.default_lease_time``;
global_max_lease_time=``dhcpdata.global.max_lease_time``;
global_authoritative=``dhcpdata.global.authoritative``;

printf "option domain-name %s;\n" $global_domain_name 
printf "default-lease-time %s;\n" $global_default_lease_time
printf "max-lease-time %s;\n" $global_max_lease_time

if [[ "$global_authoritative" == true ]] ; then
	printf "authoritative;\n"
fi

for subnet_key in ``dhcpdata.subnets[!]``
do
	subnet=``dhcpdata.subnets[$subnet_key].subnet``
	netmask=``dhcpdata.subnets[$subnet_key].netmask``
	range_start=``dhcpdata.subnets[$subnet_key].range_start``
	range_end=``dhcpdata.subnets[$subnet_key].range_end``
	routers=``dhcpdata.subnets[$subnet_key].routers``
	broadcast=``dhcpdata.subnets[$subnet_key].broadcast``
	printf "subnet %s netmask %s {\n" $subnet $netmask
	printf "\toption subnet-mask %s\n" $netmask
	printf "\trange %s %s;\n" $range_start $range_end
	printf "\toption routers %s;\n" $routers
	printf "\toption broadcast-address %s;\n" $broadcast
        printf "\toption domain-name-servers"
	for dns_key in ``dhcpdata.subnets[$subnet_key].dns_servers[!]``
        do
                dns=``dhcpdata.subnets[$subnet_key].dns_servers[$dns_key]``
        	printf " %s" $dns
	done
	printf ";\n}\n"
done

# Parse data from hosts
for host in ``hostdata.hosts[!]``; 
do
	# Take the first domain as primary to make things easier
	for domain in ``hostdata.hosts[$host].domains[!]``
	do
		domainname=``hostdata.hosts[$host].domains[$domain]``
		break;
	done
	
	hostname=``hostdata.hosts[$host].hostname``
	host_type=``hostdata.hosts[$host].host_type``
	comments=``hostdata.hosts[$host].comments``
	for interface in ``hostdata.hosts[$host].interfaces[!]``
	do
		if [[ ``hostdata.hosts[$host].interfaces[$interface].primary`` -eq "true" ]] ; then
			mac=``hostdata.hosts[$host].interfaces[$interface].mac``
		fi
	done

	if [[ -n "$mac" && -n "$hostname" && -n "$domainname" && "$host_type" != "lxc" ]] ; then
		printf "# %s \n" "$comments"
		printf "host %20s {\n" $hostname
		printf "\thardware ethernet %15s;\n" $mac
		printf "\tfixed-address %30s;\n" "$hostname.$domainname"
		printf "}\n\n"
	fi
done
