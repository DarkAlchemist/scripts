#!/bin/sh

#
# Simple conflict resolution script for ownCloud files.
#
# I was in need of something simple and effective because
# a glitch in the file system caused nearly total duplication
# of my ownCloud data folder.
#
# This script does not handle directories and will error
# out cleanly for directory items. It does so by a fairly simple
# method - a conflicted directory is a zip, so when you go
# searching for bobspics.zip and you can't find it, you can
# assume that this is a directory.
#
# Example usage:
#  sh conflicter.sh data/gitsnik/files
#
# SCRIPT KIDDIE PROTECTION ENABLED
#
if [ "$1" = "" ];
then
   echo "[-] Error require path to home cloud folder"
   exit 1;
fi

cd "$1"
find . -name '*_conflict*' -type f | while read FNAME;
do
   echo "[DEBUG] $FNAME"
   CNAME=$(echo $FNAME | perl -pe 's/_conflict.*\.([a-zA-Z]{1,4})$/.\1/g')
   if [ -f "$CNAME" ];
   then
      echo "[DEBUG] $CNAME"
      CNAMEMD=$(openssl md5 "$CNAME" | awk -F'= ' '{print $2}')
      FNAMEMD=$(openssl md5 "$FNAME" | awk -F'= ' '{print $2}')
      echo "[DEBUG] $FNAMEMD $CNAMEMD"
      if [ "$FNAMEMD" = "$CNAMEMD" ];
      then
         echo "[+] Conflict Resolved"
         echo rm "\"$FNAME\""
      else
         echo "[=] Conflict Unresolved ( $FNAME )"
      fi
   else
      echo "[-] $CNAME does not exist. Probably is a directory"
   fi
done
