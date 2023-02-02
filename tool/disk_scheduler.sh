#!/bin/bash

# 0 表示SSD， 1表示HDD
expect_type=([0]="noop" [1]="noop")
# flag=False
disks=$(lsblk -d -o name | grep -v NAME)
for i in $disks; do
    type=$(cat /sys/block/$i/queue/rotational)
    scheduler=$(cat /sys/block/$i/queue/scheduler | awk -F"[" '{print $2}' | awk -F"]"  '{print $1}')
    if [ ${expect_type[$type]} != $scheduler ]; then
        # echo_format " $i 调度方式" FAILD "expect scheduler: ${expect_type[$type]}, current: $scheduler"
        echo none > /sys/block/$i/queue/scheduler
        # flag=True
    fi
    # echo "$i" "tyep: $type" "scheduler: $scheduler"
