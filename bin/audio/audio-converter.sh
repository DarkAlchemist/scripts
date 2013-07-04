#!/bin/bash

source /usr/local/lib/stdlib.sh

DIR=$( dirname "$( readlink -f $0 )" )

# REQUIREMENTS: lame, flac, mp3gain, sed

TAGCOPYLOC="$DIR/tagcopy.sh"

LAMEENCOPTS="-V 0 --vbr-new -q 0 --silent"
FLACENCOPTS="-5 -V -s"
FLACDECODEOPTS="-cds"
MP3GAINOPTS="-rq"

OUTTYPE="side"

function flac2mp3(){
	local src="$1"
	local dst="$2"
	echo "Converting $src to mp3..."
	flac ${FLACDECODEOPTS} "$src"  | lame ${LAMEENCOPTS} - "$dst"
}

function applyGain(){
	local src="$1"
	if [[ "$ADDGAIN" -eq 1 ]] ; then
		echo "Applying gain to $src"
		mp3gain ${MP3GAINOPTS} "$src"
	fi
}

function copyTag(){
	local src="$1"
	local dst="$2"
	if [[ "$COPYTAG" -eq 1 ]] ; then
		echo "Copying tag from $src ..."
		${TAGCOPYLOC} "$src" "${dst}" 1>/dev/null
	fi
}

function moveFile(){
	local dir="$1"
	local src="$2"
	local dstfile="${src#"${dir}"}"
	case ${OUTTYPE} in
		sub)
			newdir="$dir/MP3/$( dirname $dstfile )"
			dst="$dir/MP3/$dstfile"
			;;
		side)
			newdir="$( echo "$dir" | sed "s/ (FLAC)//" ) (VBR)/$( dirname $dstfile )"
			dst="$( echo "$dir" | sed "s/ (FLAC)//" ) (VBR)/$dstfile"
			;;
	esac
	mkdir -p "$newdir"
	mv "$src" "$dst"	
}
	
function usage {
	echo -e "Usage directions:"
	echo -e "	-m	defines mode, available modes are flac2mp3, wav2mp3 and wav2flac"
	echo -e "	-d	directory containing source files for conversion"
	echo -e "	-g	enable mp3gain mode, this applies gain to achieve 89dB per mp3. Applies to MP3 conversion only"
	echo -e "	-t	copy tags from source files while converting to MP3"
	echo -e "	-o	output folder structure type. Modes are sub and side. Defaults to side"
	echo -e "	-r	recurse into subdirectories, useful for multidisc albums"
	echo -e "Example usage for recursive, tag copy and gain during conversion: $0 -r -t -g -m flac2mp3 -d /path/to/directory"
}

while getopts ":m:d:ghto:r" opt ; do
	case $opt in
		m)	# conversion mode
			MODE="${OPTARG}" ;;
		d)	MUSICDIR=$( readlink -f "${OPTARG}" )
		o)	# Directory to search
			OUTTYPE="${OPTARG}" ;;
		g)	# Apply gain
			ADDGAIN=1 ;;
		h)	HELPMODE=1 ;;
		t)	COPYTAG=1 ;;
		r)	RECURSE=1 ;;
		\?)	echo "Invalid option" ;;
	esac
done

if [[ -n "${MODE}" ]] ; then
	
	OLDIFS=$IFS
	IFS="$( echo -ne "\\n\\b" )"
	case ${MODE} in
		flac2mp3)
			if [[ -d "${MUSICDIR}" ]] ; then
				
				if [[ "${RECURSE}" -ne 1 ]] ; then
					FLACFILES=$( find "${MUSICDIR}" -type f -maxdepth 1 | grep ".flac" | sort )	
				else
					FLACFILES=$( find "${MUSICDIR}" -type f | grep ".flac" | sort )	
				fi

				for FILE in ${FLACFILES}
				do
					flac2mp3 "$FILE" "${FILE%.*}.mp3"
		
					applyGain "${FILE%.*}.mp3"		

					copyTag "$FILE" "${FILE%.*}.mp3"

					moveFile "${MUSICDIR}" "${FILE%.*}.mp3"
				done
			else
				echo "ERROR: ${MUSICDIR} is not a directory"
				exit 1
			fi
			;;
		wav2mp3)
			if [[ -n "${SELDIR}" && -d "${SELDIR}" ]] ; then
				WAVFILES=$( ls -1 "${SELDIR}" | grep ".wav")
				mkdir -p "${SELDIR}/MP3"
				for FILE in ${WAVFILES}
				do
					FILE="${FILE%.*}"
					echo "Processing: ${FILE}"
					lame ${LAMEENCOPTS} "${SELDIR}/${FILE}.wav" "${SELDIR}/${FILE}.mp3"
					# Apply gain if set
					if [[ $GAINMODE -eq 1 ]] ; then
						mp3gain ${MP3GAINOPTS} "${SELDIR}/${FILE}.mp3"
					fi
					# Move files into respective directories
					mv "${SELDIR}/${FILE}.mp3" "${SELDIR}/MP3/${FILE}.mp3"
				done
			else
				echo "ERROR: ${SELDIR} is not a directory"
				exit 1
			fi
			;;
		wav2flac)
			if [[ -n "${SELDIR}" && -d "${SELDIR}" ]] ; then
				WAVFILES=$( ls -1 "${SELDIR}" | grep ".wav")
				mkdir -p "${SELDIR}/FLAC"
				for FILE in ${WAVFILES}
				do
					FILE="${FILE%.*}"
					echo "Processing: ${FILE}"
					flac ${FLACENCOPTS} -o "${SELDIR}/${FILE}.flac" "${SELDIR}/${FILE}.wav"
					# Move files into respective directories
					mv "${SELDIR}/${FILE}.flac" "${SELDIR}/FLAC/${FILE}.flac"
				done
			else
				echo "ERROR: ${SELDIR} is not a directory"
				exit 1
			fi
			;;
	esac
elif [[ "${HELPMODE}" -eq 1 ]] ; then
	usage
else	
	echo "ERROR: No mode specified"
	exit 1
fi
exit 0
