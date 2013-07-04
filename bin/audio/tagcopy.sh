#!/bin/bash
# 
# Script to copy tags from one format to another
# Currently only supports flac to mp3 

INPUT=$1
OUTPUT=$2
# TODO: Replace with mktemp
TMPCOVER="/tmp/cover.jpg"

if [[ -e "${INPUT}" && -e "${OUTPUT}" ]] ; then
	INEXT="${INPUT##*.}"

	case $INEXT in
		flac)
			ALBUMARTIST=$( metaflac --show-tag="ALBUM ARTIST" "${INPUT}" | sed -r "s/^ALBUM ARTIST=(.*)$/\1/I" )
			ARTIST=$( metaflac --show-tag="ARTIST" "${INPUT}" | sed -r "s/^ARTIST=(.*)$/\1/I" )
			ALBUM=$( metaflac --show-tag="ALBUM" "${INPUT}" | sed -r "s/^ALBUM=(.*)$/\1/I" )
			TITLE=$( metaflac --show-tag="TITLE" "${INPUT}" | sed -r "s/^TITLE=(.*)$/\1/I" )
			YEAR=$( metaflac --show-tag="DATE" "${INPUT}" | sed -r "s/^DATE=(.*)$/\1/I" )
			GENRE=$( metaflac --show-tag="GENRE" "${INPUT}" | sed -r "s/^GENRE=(.*)$/\1/I" )
			COMMENT=$( metaflac --show-tag="COMMENT" "${INPUT}" | sed -r "s/^COMMENT=(.*)$/\1/I" )
			COMPOSER=$( metaflac --show-tag="COMPOSER" "${INPUT}" | sed -r "s/^COMPOSER=(.*)$/\1/I" )
			ENCODEDBY=$( metaflac --show-tag="ENCODEDBY" "${INPUT}" | sed -r "s/^ENCODEDBY=(.*)$/\1/I" )
			TRACKNUMBER=$( metaflac --show-tag="TRACKNUMBER" "${INPUT}" | sed -r "s/^TRACKNUMBER=(.*)$/\1/I" )
			LABEL=$( metaflac --show-tag="LABEL" "${INPUT}" | sed -r "s/^LABEL=(.*)$/\1/I" )
			
			metaflac --export-picture-to="${TMPCOVER}" "${INPUT}"
			;;
		mp3)
			;;
	esac
	
	OUTEXT="${OUTPUT##*.}"

	case $OUTEXT in
		mp3)
			eyeD3 -2 --set-text-frame=TPE1:"${ARTIST}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TPE2:"${ALBUMARTIST}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TIT2:"${TITLE}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TALB:"${ALBUM}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TYER:"${YEAR}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TRCK:"${TRACKNUMBER}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TCON:"${GENRE}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TCOM:"${COMPOSER}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TENC:"${ENCODEDBY}" "${OUTPUT}"
			eyeD3 -2 --set-text-frame=TPUB:"${LABEL}" "${OUTPUT}"
			eyeD3 -2 --comment=eng::"${COMMENT}" "${OUTPUT}"

			# if we have a cover then we need to add to the id3 tag
			if [[ -e "${TMPCOVER}" ]] ; then 
				eyeD3 -2 --add-image="${TMPCOVER}":FRONT_COVER "${OUTPUT}"
			fi
			# id3v2.4 seems to be incompatible with a lot of things so convert to 2.3
			eyeD3 --to-v2.3 "${OUTPUT}"
			;;
	esac

if [[ -e "${TMPCOVER}" ]] ; then 
	rm -f "${TMPCOVER}"
fi

else
	echo "ERROR: Input or output file is missing"
	exit 1
fi
