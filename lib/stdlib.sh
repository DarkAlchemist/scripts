#!/bin/bash

# Global variable definitions

LIBDIR="/usr/local/lib"

# Useful global functions

function execInChroot(){
	location="$( readlink -f "$1" )"
	exec_command="$2"

	mount -t sysfs sysfs "$location"/sys
	mount --bind /dev "$location"/dev
	mount -t proc proc "$location"/proc
	mount -t devpts devpts "$location"/dev/pts
	
	chroot "$location" /bin/bash -c "$exec_command"

	umount "$location"/{dev/pts,dev,sys,proc}
}

function getIPAddr(){
	local interface="$1"
	if [[ -n "$interface" ]] ; then
		echo "$( /sbin/ifconfig $1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
	fi
}

function mkTmpFile(){
	local tmpfile=$( mktemp tmp.XXXXXXXXXXXXXX )
	# store files created by mktemp in an array for deleting later
	if [[ -z "${STDLIB_MKTMP}" ]] ; then
		STDLIB_MKTMP=()
	fi
	STDLIB_MKTMP=( '$tmpfile' )
	echo "$tmpfile"
}

function stdCleanup(){
	# Clean up files created by mktemp
	if [[ -z "${STDLIB_MKTMP}" ]] ; then
		local len=${#STDLIB_MKTMP[@]}
		for (( local i=0; i<${len}; i++ ));
		do
			rm "${STDLIB_MKTMP[$i]}"
		done
	fi
}
