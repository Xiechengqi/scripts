#!/bin/bash
# 成功退出 0 ，失败退出 1，其他退出 2

Color_Yellow="\033[33m"
Color_Green="\033[32m"
Color_Red="\033[31m"
Color_Blue="\033[36m"
Color_Suffix="\033[0m"

echo_format() {
    if [ $# -ge 1 ] && [ $# -lt 2 ]; then
        echo -e "$Color_Yellow $1 $Color_Suffix"
    elif [ $2 == "PASS" ]; then
        echo -e "$Color_Yellow - 检查$1结束 $Color_Suffix"'\t\t'"$Color_Green $2 $Color_Suffix"'\t\t'"$Color_Blue $3 $Color_Suffix"
    elif [ $2 == "FAILD" ]; then
        echo -e "$Color_Yellow - 检查$1结束 $Color_Suffix"'\t\t'"$Color_Red $2 $Color_Suffix"'\t\t'"$Color_Blue $3 $Color_Suffix"
    else
        echo -e "$1"'\t'"$2"'\t'"$3"
    fi
}

min_max() {
    max=$1; min=$1; sum=0
    for i in $@; do
        [ $(echo "$max < $i" | bc) -eq 1 ] && max="$i"
        [ $(echo "$min > $i" | bc) -eq 1 ] && min="$i"
        sum=$(echo "ibase=10; scale=2; $sum+$i" | bc)
    done
}

hugepage_check() {
    echo_format "【- 开始检查 Hugepage .....】"
    res=$(cat /proc/meminfo | grep HugePages_Total)
    echo $res
    if [ $(echo $res | awk '{print $NF}') -eq 0 ]; then
        echo_format "hugepage关闭" PASS
    else
        echo_format "hugepage关闭" FAILD "expect HugePages_Total: 0, current: $res"
        return 1
    fi
}

swap_check() {
    echo_format "【- 开始检查 Swap .....】"
    res=$(cat /proc/meminfo | grep SwapTotal)
    echo $res
    if [ $(echo $res | awk '{print $2}') -eq 0 ]; then
        echo_format "swap关闭" PASS
    else
        echo_format "swap关闭" FAILD "expect SwapTotal: 0, current: $res"
        return 1
    fi
}

numa_used_check() {
    allow_rate=0.01; memfree=""
    echo_format "【- 开始检查 NUMA used, 期望node偏差比例小于$allow_rate .....】"
    node_num=$(numactl -H | grep available | awk -F"nodes" '{print $1}' | awk '{print $2}')
    total=$(numastat -m | grep MemFree | awk '{print $NF}')
    for i in $(seq 1 $node_num); do
        free=$(numastat -m | grep MemFree | awk -v i="$i" '{print $(i+1)}')
        used=$(numastat -m | grep MemUsed | awk -v i="$i" '{print $(i+1)}')
        memfree=$memfree' '$free
        memused=$memused' '$used
    done
    min_max $memfree
    free_rate=$(echo "ibase=10; scale=2; ($max-$min)/$max" | bc)
    min_max $memused
    used_rate=$(echo "ibase=10; scale=2; ($max-$min)/$max" | bc)
    if [ $(echo "$free_rate <= $allow_rate" | bc) -eq 1 ] || [ $(echo "$used_rate <= $allow_rate" | bc) -eq 1 ]; then
        numactl -H
        echo_format "numa node均匀" PASS
    else
        echo_format "numa node均匀" FAILD "numa node偏差比例大于$allow_rate ,当前numa情况如下:"
        numactl -H
        return 1
    fi
}

disk_scheduler_check() {
    echo_format "【- 开始检查 DISK 调度方式, 0 表示SSD, 1表示HDD .....】"
    # 0 表示SSD， 1表示HDD
    expect_type=([0]="noop" [1]="noop"); flag=False
    disks=$(lsblk -d -o name | grep -v NAME)
    for i in $disks; do
        type=$(cat /sys/block/$i/queue/rotational)
        scheduler=$(cat /sys/block/$i/queue/scheduler | awk -F"[" '{print $2}' | awk -F"]"  '{print $1}')
        if [ ${expect_type[$type]} != $scheduler ]; then
            echo_format " $i 调度方式" FAILD "expect scheduler: ${expect_type[$type]}, current: $scheduler"
            flag=True
        fi
        echo "$i" "tyep: $type" "scheduler: $scheduler"
    done
    if [ $flag == "False" ]; then
        echo_format "DISK调度方式" PASS
    else
        return 1
    fi
}

mongodb_numactl_check() {
    echo_format "【- 开始检查 MongoDB NUMA 参数.....】"
    IFS=$'\n'; flag=False
    mongodbs=$(ps -ef | grep mongo | grep -vE "rotatelogs|rsync|backup|exporter" | grep -v grep)
    for i in $mongodbs; do
        cmd=$(echo $i | awk '{print $8}' | awk '{sub(/.{1}$/,"")}1')
        port=$(echo $i | awk -F"--port" '{print $2}' | awk '{print $1}')
        res=$(${cmd} 127.0.0.1:${port} --eval 'db.hostInfo()' | grep 'numaEnabled')
        if [ $(echo $res | awk '{print $3}') != "false" ]; then
            echo_format $cmd $res
            echo_format "$cmd numa设置" FAILD "expect numaEnabled: false, current: true"
            flag=True
        elif [ $(echo $res | awk '{print $3}') == "false" ]; then
            echo_format $cmd $res
            echo_format "$cmd numa设置" PASS
        fi
    done
    if [ $flag != "False" ]; then
        return 1
    fi
}

kernel_sysctl_check() {
    echo_format "【- 开始检查 kernel sysctl 配置 .....】"
    sysctl -a --ignore 2>&1 | grep -E "ip_local_port_range|tcp_keepalive_intvl| >
        overcommit_memory|swappiness|dirty_ratio|min_free_kbytes"
}

all_checks="""
    hugepage_check
    swap_check
    numa_used_check
    disk_scheduler_check
    mongodb_numactl_check
    kernel_sysctl_check
"""

start_all() {
    echo "----------- node parameter check -----------"
    TOTAL=0; PASS=0; FAILD=0
    for item in $all_checks; do
        let TOTAL++
        $item
        if [ $? -eq 0 ]; then
            let PASS++
        else
            let FAILD++
        fi
        echo
    done
    echo "-------------------------------------"
    echo_format "TOTAL: $TOTAL      PASS: $PASS         FAILD: $FAILD"
}

start_all
