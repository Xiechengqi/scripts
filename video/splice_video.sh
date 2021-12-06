#!/usr/bin/env bash

#
# 2021/12/04
# 使用 ffmpeg 拼接视频
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/video/splice_video.sh | sudo bash -s $(pwd)/mp4 $(pwd)/output 20
# bash splice_video.sh [视频输入目录] [视频输出目录] [需要生成视频总量大小(G)]
#

trap "_clean" EXIT

_clean() {
[ ".${inputMp4FilePath}" != "." ] && cd ${inputMp4FilePath} && rm -f $$_*
}


function rand(){
min=$1
max=$(($2 - $min + 1))
num=$(date +%s%N)
echo $(($num % $max + $min))
}

main() {

inputMp4FilePath=$1
outputMp4FilePath=$2 && mkdir -p ${outputMp4FilePath}
mp4TotalSize=$3
inputMp4List="${inputMp4FilePath}/$$_input_mp4_list"

cd ${inputMp4FilePath}

# 获取输入视频文件名最大数字前缀，用于取随机数范围上限
max=$(ls | grep -E '[0-9]+.mp4' | awk -F '.mp4' '{print $1}' | sort -rn | head -1)
[ $max -lt 100 ] && echo "The sum of videos too small, should be greater than 100" && exit 1

while :
do

mp4NowSize=`expr $(du -sm ${outputMp4FilePath} | awk '{print $1}') / 1024`
echo "${outputMp4FilePath} size: ${mp4NowSize}G"
[ "${mp4NowSize}" -ge "${mp4TotalSize}" ] && break

# ffmpeg 拼接视频，随机从视频素材库取 n 个视频拼接，确保最终生成视频大小大于 17G
echo > ${inputMp4List}

outputFileSize="0"
echo "${outputFileSize}"
while :
do
[ "${outputFileSize}" -ge "17408" ] && break
echo "${outputFileSize}"
fileName="$(rand 1 ${max}).mp4"
tmpOutputFileSize=`expr $(du -sm ${fileName} | awk '{print $1}')`
outputFileSize=`expr ${outputFileSize} + ${tmpOutputFileSize}`
echo "file '${fileName}'" >> ${inputMp4List}
done

echo "start splice video ..."
cat ${inputMp4List}

echo "ffmpeg -f concat -i ${inputMp4List} -c copy ${outputMp4FilePath}/$(date +%Y%m%d-%H%M%S).mp4"
ffmpeg -f concat -i ${inputMp4List} -c copy ${outputMp4FilePath}/$(date +%Y%m%d-%H%M%S).mp4

sleep 5

done

}

main $@
