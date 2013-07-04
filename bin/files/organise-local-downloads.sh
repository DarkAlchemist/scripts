#!/bin/env bash

DOWNLOADS_DIR="$HOMEPATH\\Downloads\\"
DOWNLOAD_FILES="$( ls -1 "${DOWNLOADS_DIR}" )"

MUSIC_DIR="${DOWNLOADS_DIR}Incoming Music\\"
VIDEOS_DIR="${DOWNLOADS_DIR}Incoming Videos\\"
DOCS_DIR="${DOWNLOADS_DIR}Incoming Docs\\"
IMAGES_DIR="${DOWNLOADS_DIR}Incoming Images\\"
INSTALLERS_DIR="${DOWNLOADS_DIR}Incoming Installers\\"

OLDIFS=$IFS
IFS="$( echo -ne "\\n\\b" )"

for FILE in ${DOWNLOAD_FILES} ; 
do
	if [ -f "${DOWNLOADS_DIR}${FILE}" ] ; then 
		case "${FILE}" in
			*.wav|*.mp3|*.flac|*.m4a|*flac*|*mp3*)
				mkdir -p "${MUSIC_DIR}"
				mv "${DOWNLOADS_DIR}${FILE}" "${MUSIC_DIR}${FILE}"
				;;
				
			*.mkv|*.mp4|*.avi|*.wmv|*.mov|*.MOV)
				mkdir -p "${VIDEOS_DIR}"
				mv "${DOWNLOADS_DIR}${FILE}" "${VIDEOS_DIR}${FILE}"
				;;
				
			*.xlx|*.xlsx|*.doc|*.docx|*.pdf)
				mkdir -p "${DOCS_DIR}"
				mv "${DOWNLOADS_DIR}${FILE}" "${DOCS_DIR}${FILE}"
				;;
			
			*.png|*.bmp|*.jpg)
				mkdir -p "${IMAGES_DIR}"
				mv "${DOWNLOADS_DIR}${FILE}" "${IMAGES_DIR}${FILE}"
				;;
				
			*.exe|*.msi|*.rar|*.7z|*.tar.gz|*.tar|*.zip)
				mkdir -p "${INSTALLERS_DIR}"
				mv "${DOWNLOADS_DIR}${FILE}" "${INSTALLERS_DIR}${FILE}"
				;;			
				
			*.torrent)
				rm "${DOWNLOADS_DIR}${FILE}"
				;;
		
		esac
	fi
	
done
IFS=$OLDIFS
exit 0