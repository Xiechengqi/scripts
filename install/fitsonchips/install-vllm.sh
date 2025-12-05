#!/usr/bin/env bash

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

export installPath="/data/fitsonchips-vllm"
export IMAGE="squeezebits/fitsonchips-gpu-vllm:latest"
mkdir -p ${installPath}

export DEVICE_KEY=$1
[ ".${DEVICE_KEY}" = "." ] && ERROR "bash [DEVICE_KEY] [DEVICE]"

INFO "docker pull ${IMAGE}" && docker pull ${IMAGE} || ERROR "Pull image fail ..."

export DEVICE=$2
if [ ".${DEVICE}" = "." ]
then
cat > ${installPath}/docker-run.sh << EOF
#!/usr/bin/env bash

name="fitsonchips-vllm"
docker rm -f \${name}
docker run -itd \\
--restart=unless-stopped \\
--gpus all \\
-e DEVICE_KEY=${DEVICE_KEY} \\
--name \${name} \\
${IMAGE} \\
./start_worker.sh
EOF
eles
cat > ${installPath}/docker-run.sh << EOF
#!/usr/bin/env bash

name="fitsonchips-vllm"
docker run -itd \\
--restart=unless-stopped \\
--gpus '"device=0"' \\
-e DEVICE_KEY=${DEVICE_KEY} \\
--name \${name} \\
${IMAGE} \\
./start_worker.sh
EOF
fi
EXEC "chmod +x ${installPath}/docker-run.sh"
INFO "bash ${installPath}/docker-run.sh" && bash ${installPath}/docker-run.sh || ERROR "Run fail ..."

}

main $@
