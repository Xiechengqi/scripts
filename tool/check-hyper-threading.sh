#!/usr/bin/env bash

#
# 2022/12/07
# xiechengqi
# 检查是否开启超线程
#

main() {

physical_cpu_num=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
single_logical_cpu_num=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | wc -l)
logical_cpu_num=$(expr ${physical_cpu_num} \* ${single_logical_cpu_num})
real_logical_cpu_num=$(cat /proc/cpuinfo | grep "processor" | wc -l)
[ "${real_logical_cpu_num}" -gt "${logical_cpu_num}" ] && echo "true" || echo "false"

}

main $@
