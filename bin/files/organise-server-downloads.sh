#!/bin/env bash

OLDIFS=$IFS
IFS=$( echo -ne "\n\b" )

if [[ -f "$1" ]] ; then
	source "$1"
else
	echo >&2 "Error: Config file not specified"
	exit 1
fi

TV_REGEX="^(.*)(\.|[[:space:]]*)S([0-9]{1,2})(\.|[[:space:]]*)E([0-9]{1,2}).*(\.|[[:space:]])(avi|mp4|mkv)$"

NEW_EPS=$( ls -1 "$DOWNLOADS_DIR" | grep -E "$TV_REGEX" )

for EPISODE in $NEW_EPS ;
do
	# Rearrange filename to be correct 
	NEW_NAME=$( echo "$EPISODE" | sed -r "s/\./ /g" | sed -r "s/${TV_REGEX}/\1 S\3E\5\.\7/" | sed -r "s/  / /g" )
	echo "Moving ${NEW_NAME} to ${TV_UNWATCHED_DIR}${NEW_NAME}"
	mv "${DOWNLOADS_DIR}${EPISODE}" "${TV_UNWATCHED_DIR}${NEW_NAME}"
done

FILEMOVIEREGEX="^(.*)(\([0-9]{4}\)).*(DVDRip|BDRip|BRRip|DVD Rip|DVDSCR)*.*(\.|[[:space:]])(avi|mp4|mkv)$"

# Folder should match files too but different solution for renaming 
FOLDERMOVIEREGEX="^(.*)(\([0-9]{4}\)).*(DVDRip|BDRip|BRRip|DVD Rip|DVDSCR)*.*(\.|[[:space:]]*)(.*)$"

MOVIES=$( ls -1 "$DOWNLOADS_DIR" | grep -E "$FOLDERMOVIEREGEX" )

for MOVIE in $MOVIES ;
do
	echo $MOVIE
	if  test -f "${DOWNLOADS_DIR}${MOVIE}" ; then 
		NEW_NAME=$( echo "$MOVIE" | sed -r "s/\./ /g" | sed -r "s/${FILEMOVIEREGEX}/\1 \2\.\5/" | sed -r "s/  / /g" )
	else
		NEW_NAME=$( echo "$MOVIE" | sed -r "s/\./ /g" | sed -r "s/${FOLDERMOVIEREGEX}/\1 \2/" | sed -r "s/  / /g" )
	fi
	echo "Moving ${NEW_NAME} to ${MOVIES_UNWATCHED_DIR}${NEW_NAME}"
	mv "${DOWNLOADS_DIR}${MOVIE}" "${MOVIES_UNWATCHED_DIR}${NEW_NAME}"
done
IFS=$OLDIFS
