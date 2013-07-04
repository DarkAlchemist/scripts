#!/bin/bash

# source bash JSON parser
source /usr/local/lib/stdlib.sh
source $LIBDIR/ticktick.sh

function generateForwardLookupConf(){
	if [ ! -z "$__tick_export_data" ]; then
		eval $__tick_export_data
	fi
	if [[ "$FILEMODE" -eq 1 ]] ; then
		exec 1>>named.conf
	fi
	for domain_key in ``domaindata.domains[!]``; 
	do
		domain=``domaindata.domains[$domain_key].domain``
		printf "zone \"%s\" {\n" $domain
		printf "\t type master;\n"
		printf "\t file \"/var/bind/zones/%s.zone\";\n" $domain
		printf "\t allow-query { trusted; };\n"
		printf "};\n"
	done
}

function generateForwardLookup(){
	if [ ! -z "$__tick_export_data" ]; then
		eval $__tick_export_data
	fi
	serial=$( date +%s )
	for domain in ``domaindata.domains[!]``; 
	do
		domain_name=``domaindata.domains[$domain].domain``
		if [[ "$FILEMODE" -eq 1 ]] ; then
			exec 1>$domain_name.zone
		fi
		soa_host=``domaindata.domains[$domain].soa_host``
		soa_contact=``domaindata.domains[$domain].soa_contact``
		printf "\$TTL 600\n"
		printf "; %s\n" $domain_name
		printf "@ IN SOA %30s. %30s. (\n" $soa_host $soa_contact
		printf "%20s ; serial\n" $serial
		printf "%20s ; refresh\n" "12"
		printf "%20s ; retry\n" "1h"
		printf "%20s ; expire\n" "2w"
		printf "%20s ; minimum\n" "1h"
		printf ")\n"
		
		for MX in ``domaindata.domains[$domain].mx[!]``
		do
			mx=``domaindata.domains[$domain].mx[$MX].host``
			weight=``domaindata.domains[$domain].mx[$MX].weight``
			printf "%-30s IN %8s %8s %30s.\n" " " "MX" $weight $mx
		done
		
		nameserver=``domaindata.domains[$domain].ns``
		printf "%-30s IN %8s %30s.\n" " " "NS" $nameserver
		
		# Parse data from hosts, checking against domain
		for host in ``hostdata.hosts[!]``; 
		do
			match=false
			for host_domain_index in ``hostdata.hosts[$host].domains[!]``
			do
				host_domain=``hostdata.hosts[$host].domains[$host_domain_index]``
				host_type=``hostdata.hosts[$host].host_type``
				if [[ "$host_domain" = "$domain_name" ]] ; then
					match=true
				fi
			done
			if [[ $match == true ]] ; then
				hostname=``hostdata.hosts[$host].hostname``
				for interface in ``hostdata.hosts[$host].interfaces[!]``
				do
					if [[ ``hostdata.hosts[$host].interfaces[$interface].primary`` -eq "true" ]] ; then
						ip=``hostdata.hosts[$host].interfaces[$interface].ip``
						primary_ip="$ip"
						printf "%-30s IN %8s %30s\n" $hostname "A" $ip
					else
						ip=``hostdata.hosts[$host].interfaces[$interface].ip``
						if=``hostdata.hosts[$host].interfaces[$interface].interface``
						printf "%-30s IN %8s %30s\n" $hostname-$if "A" $ip
					fi
				done
				for alias in ``hostdata.hosts[$host].aliases[!]``
				do
					cname=``hostdata.hosts[$host].aliases[$alias]``
					if `echo "$cname" | grep -Ei "^mx" >/dev/null` ; then
						# use the primary ip only, should be suitable for small network
						printf "%-30s IN %8s %30s\n" $cname "A" $primary_ip
					else
						printf "%-30s IN %8s %30s\n" $cname "CNAME" $hostname
					fi
				done
			fi
		done
	done
}


function generateReverseLookupConf(){
	if [ ! -z "$__tick_export_data" ]; then
		eval $__tick_export_data
	fi
	if [[ "$FILEMODE" -eq 1 ]] ; then
		exec 1>>named.conf
	fi
	for reverse_key in ``domaindata.reverse[!]``; 
	do
		reverse_ip=``domaindata.reverse[$reverse_key].reverse_ip_range``
		printf "zone \"%s\" {\n" "$reverse_ip.in-addr.arpa" 
		printf "\t type master;\n"
		printf "\t file \"/var/bind/zones/%s.zone\";\n" "$reverse_ip.in-addr.arpa"
		printf "\t allow-query { trusted; };\n"
		printf "};\n"
	done
}

function generateReverseLookup(){
	if [ ! -z "$__tick_export_data" ]; then
		eval $__tick_export_data
	fi
	serial=$( date +%s )
	for reverse_key in ``domaindata.reverse[!]``; 
	do
		ip_range=``domaindata.reverse[$reverse_key].ip_range``
		reverse_zone=``domaindata.reverse[$reverse_key].reverse_ip_range``
		reverse_zone="$reverse_zone.in-addr.arpa"
		if [[ "$FILEMODE" -eq 1 ]] ; then
			exec 1>$reverse_zone.zone
		fi
		soa_host=``domaindata.reverse[$reverse_key].soa_host``
		soa_contact=``domaindata.reverse[$reverse_key].soa_contact``
		printf "\$TTL 600\n"
		printf "; %s\n" $reverse_zone
		printf "@ IN SOA %30s. %30s. (\n" $soa_host $soa_contact
		printf "%20s ; serial\n" $serial
		printf "%20s ; refresh\n" "12"
		printf "%20s ; retry\n" "1h"
		printf "%20s ; expire\n" "2w"
		printf "%20s ; minimum\n" "1h"
		printf ")\n"
		
		nameserver=``domaindata.reverse[$reverse_key].ns``
		printf "%-30s IN %8s %30s.\n" "$reverse_zone." "NS" $nameserver
		
		# Parse data from hosts, checking against domain
		for host in ``hostdata.hosts[!]``; 
		do
			for host_domain_index in ``hostdata.hosts[$host].domains[!]``
			do
				host_domain=``hostdata.hosts[$host].domains[$host_domain_index]``
				host_type=``hostdata.hosts[$host].host_type``
				hostname=``hostdata.hosts[$host].hostname``
				for interface in ``hostdata.hosts[$host].interfaces[!]``
				do
					ip=``hostdata.hosts[$host].interfaces[$interface].ip``
					if `echo "$ip" | grep -E "^$ip_range" >/dev/null`; then
						lastoctet=$( echo "$ip" | cut -d'.' -f 4 )
						printf "%-30s IN %8s %30s\n" $lastoctet "PTR" "$hostname.$host_domain."
						for alias in ``hostdata.hosts[$host].aliases[!]``
						do
							cname=``hostdata.hosts[$host].aliases[$alias]``
							printf "%-30s IN %8s %30s\n" $lastoctet "PTR" "$cname.$host_domain."
						done
					fi
				done
			done
		done
	done 
}

DIR=$( dirname "$( readlink -f $0 )" )
MODE="$1"

if `echo "$MODE" | grep "\-\-" >/dev/null`; then
	case $MODE in
	--forward)
		FORWARD=1
		;;
	--reverse)
		REVERSE=1
		;;
	--all)
		ALL=1
		;;
	*)
		echo >&2 "ERROR: No mode of operation specified"
		exit 1
		;;
	esac
	shift
else
	echo >&2 "ERROR: No mode of operation specified"
	exit 1
fi

while getopts ":h:d:f" opt; 
do
	case $opt in
		d) DOMAINS="$OPTARG" ;;
		h) HOSTS="$OPTARG" ;;
		f) FILEMODE=1 ;;
	esac
done
# Read in domain data and parse it
DATA=`cat $DOMAINS`
tickParse "domaindata = $DATA"

# Read in hosts data and parse it
DATA=`cat $HOSTS`
tickParse "hostdata = $DATA"

# Remove named.conf if we already have a copy as we need to append
rm named.conf *.zone

if [[ "$FORWARD" -eq 1 ]] ; then
	generateForwardLookupConf
	generateForwardLookup
fi
if [[ "$REVERSE" -eq 1 ]] ; then
	generateReverseLookupConf
	generateReverseLookup
fi
if [[ "$ALL" -eq 1 ]] ; then
	generateForwardLookupConf
	generateForwardLookup
	generateReverseLookupConf
	generateReverseLookup
fi
