#!/usr/bin/env bash

for i in `mount | grep gluster | awk '{print $3}'`
do

echo "mkdir ${i}/${1}"
mkdir ${i}/${1}

done
