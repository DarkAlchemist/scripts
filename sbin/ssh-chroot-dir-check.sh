#!/bin/bash

if [[ "$USER" = "root" ]] ; then
	getent passwd | grep ":/usr/bin/scponly" |
	while read -r scponly_user
	do
		home_dir=$( echo "$scponly_user" | cut -d':' -f 6 )
		chown -R root:"Gaoled Users" "$home_dir"
		chmod -R u+rwX,g+rX,o+rX "$home_dir"
	done
else	
	echo >&2 "ERROR: This script must be run as root!"
fi
