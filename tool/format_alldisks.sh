#!/bin/bash
DISK_FN="./disks"
# find big disk and format them all
lsblk |grep 14.6T|awk '{print $1}' > $DISK_FN
while IFS='' read -r line || [[ -n "$line" ]]; do
  if [ ! -z "$line" ]; then
   if [ $? -eq 0 ]; then
     echo "processing $line..."
         sudo umount /dev/$line
         sudo wipefs -a /dev/$line
         sudo mkfs.xfs -f -i size=512 -n size=8192 /dev/$line
         #echo $cmd
   fi
  fi
done < ./$DISK_FN
