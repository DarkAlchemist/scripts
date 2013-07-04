#!/bin/bash

# Generate a basic m3u file of the same folder name
# Supports flac and mp3

DIR=$1

if [[ -d "$DIR" ]] ; then
	M3UFILE="$DIR/`basename "$DIR"`.m3u"
	cd "$DIR"
	echo "#EXTM3U" > "$M3UFILE"
	# Replace ./ in front of anything found and grep for flac or mp3
	find . | sed 's/.\///' | grep -iE "(\.flac|\.mp3)" | sort >> "$M3UFILE"
else
	echo >&2 "ERROR: Directory '$DIR' does not exist/is not a directory"	
	exit 1
fi
