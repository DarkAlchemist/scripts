#!/bin/bash

DIR="$1"
FLACOPTS="-5 -V -s"

if [[ -d "$DIR" ]] ; then
	find "$DIR" -iname \*.wav -print0 | xargs -t -0 -I input flac ${FLACOPTS} "input"
fi
