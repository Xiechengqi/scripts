#!/usr/bin/env bash

#
# 2024/03/21
# xiechengqi
# install H9 SMH Miner
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# environment
serviceName="smh-miner-h9"
version=${1-"3.0.3-1"}
installPath="/data/${serviceName}-${version}"
[ ".${DOWNLOAD}" = "." ] && ERROR "Empty env DOWNLOAD ..."
binaryName="smh-miner"
port="10088"

# check
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,lib,logs}"

# download
EXEC "curl -SsL ${DOWNLOAD}/smh/h9/${version}/${binaryName} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "curl -SsL ${DOWNLOAD}/smh/h9/${version}/libpost.so -o ${installPath}/lib/libpost.so"
EXEC "chmod +x ${installPath}/lib/libpost.so"

# conf
cat > ${installPath}/conf/config.yaml << EOF
# Plot路径
path:
- ""
# 开启扫描新文件
scanPath: false
# 扫描间隔
scanMinute: 60
extraParams:
    # 不填写用全部GPU设备，集成显卡默认也会添加，如果需要排除，需要手动设置设备列表
    device: ""
    # 文件大小，GB
    maxFileSize: 32
    # 禁用Plot
    disablePlot: false
    # PoST最大实例数，默认为CPU线程数,一个目录占3个左右的CPU核心，如果盘符过多可以限制并发数
    postInstance: 0
    # post 线程数，默认用CPU核数，0用全部线程
    postThread: 0
    # post 绑定CPU核心开始编号，-1不绑定，如果是双CPU的机器，需要进行绑定，否则可能会出现性能问题
    postAffinity: -1
    # post 绑定cpu核心递增
    postAffinityStep: 1
    # postCpuIds 同时设置了postAffinity的话，优先使用postCpuIds。指定绑定具体的核心,cpu核心用','分隔,组用';'分隔。比如12核CPU分4组，有8个目录，每组3核：0,1,2;3,4,5;6,7,8;9,10,11。那么post目录1、5是第一组CPU,目前2、6是第二组CPU,以此类推
    postCpuIds: ""
    # randomx 计算线程数，0用全部线程，有多个目录的话，randomx和post是并行状态，如果是双CPU的机器，可以将randomx单独设置到一个CPU上
    randomxThread: 0
    # randomx 绑定CPU核心开始编号，-1不绑定
    randomxAffinity: -1
    # randomx绑定cpu核心递增
    randomxAffinityStep: 1
    # flags randomx 标识,默认开启fullmem
    flags: fullmem
    # POST 证明过程中并行尝试的随机数数量，建议不要低于128，如果单个文件大于1T的，建议设置256或者288
    nonces: 128
    # 一个numUnits是64Gib
    numUnits: 15
    # 预留磁盘空间大小，单位GiB
    reservedSize: 1
    # 是否禁用InitPoST
    disableInitPost: false
    # 跳过未完成Initialized PoST的目录，在有多个目录的情况下，可以设置为true，加快初始化过程和P盘速度
    skipUninitialized: false
    # 同时plot的目录数，一个实例占3G左右的显存，一般来说显卡速度大于单块硬盘写入速度才需要设置多个实例
    plotInstance: 1
    # disablePoST 禁用PoST扫盘
    disablePoST: false
    # removeInitFailed 自动删除初始化失败的post文件夹，删除后不可恢复，谨慎填写
    removeInitFailed: false
    # 加载失败文件自动删除，删除后不可恢复，谨慎填写
    deleteLoadFail: false
    # GPU服务监听的端口
    serverPort: ${port}
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash

source /etc/profile

installPath="${installPath}"

export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${installPath}/lib
export minerName="\$(hostname)-\$(hostname -I | awk '{print \$1}')-smh-miner"

timestamp=\$(date +%Y%m%d%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log
\${installPath}/bin/${binaryName} -minerName \${minerName} -logPath \${installPath}/logs -config \${installPath}/conf/config.yaml -gpuServer -license yes &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=SMH Hpool Miner
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs ${installPath} $(dirname ${installPath})/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# cronjob: upload nvidia-smi status log
cat > ${installPath}/smh-miner-cronjob.sh << EOF
#!/usr/bin/env bash

nvidia-smi > ${installPath}/nvidia-smi.log && curl -T ${installPath}/nvidia-smi.log ${DOWNLOAD}/smh/h9/miners/$(hostname)-$(hostname -I | awk '{print $1}')
EOF
EXEC "chmod +x ${installPath}/smh-miner-cronjob.sh"
EXEC "crontab -l | grep -v 'smh-miner-cronjob.sh' | crontab"
(crontab -l;echo "*/10 * * * * bash ${installPath}/smh-miner-cronjob.sh &> /dev/null") | crontab
INFO "crontab -l" && crontab -l

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"

}

main $@
