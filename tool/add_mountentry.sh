#!/bin/bash
UUID_FN="./uuids"
DISK_FN="./disks"
# disks will be mount to /disks/disk[1-36] folder
ROOT="/gluster"
lsblk |grep 14.6T|awk '{print $1}' > $DISK_FN
i=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  if [ ! -z "$line" ]; then
   i=$((i + 1))
   if [ $? -eq 0 ]; then
     echo "processing $line..."
         uuid=`sudo blkid "/dev/$line" | awk -F"\"" '{print $2}'`
         if [ -z "$uuid" ]; then
           echo "empty uuid, skipping"
         else
       if [ ! -d $ROOT/disk$i ]; then
         sudo mkdir $ROOT/disk$i
       fi
       fsline="/dev/disk/by-uuid/$uuid $ROOT/disk$i xfs defaults,nofail,noatime 0 0"
           grep "$line" /etc/fstab
           if [ $? -ne 0 ]; then
                 echo "adding to fstab: $fsline"
             sudo bash -c "echo $fsline >> /etc/fstab"
           fi
     fi
         #echo $cmd
   fi
  fi
done < ./$DISK_FN
