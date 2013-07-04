#!/bin/bash

DIR=$1

if [[ -d "$DIR" ]] ; then
	find "$DIR" -iname *AppleDouble* -print0 | xargs -0 rm -r
	find "$DIR" -iname *DS_Store* -delete
fi
