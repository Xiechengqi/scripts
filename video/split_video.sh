#!/usr/bin/env bash

#
# 2021/12/03
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/video/split_video.sh | sudo bash -s $(pwd)/mp4 $(pwd)/source
# bash split_video.sh [源视频目录路径] [拆分后视频目录路径]
# 拆分视频
#

function secondsTotime() {
  input_seconds=$1
  hour_num=`expr ${input_seconds} / 3600`
  hours=`printf "%02d\n" ${hour_num}`
  minute_num=`expr ${input_seconds} / 60 - ${hour_num} \* 60`
  minutes=`printf "%02d\n" ${minute_num}`
  second_num=`expr ${input_seconds} - ${hour_num} \* 3600 - ${minute_num} \* 60`
  seconds=`printf "%02d\n" ${second_num}`
  echo "${hours}:${minutes}:${seconds}"
}

function produceMp4File() {

# 输入视频文件名
inputMp4FileName=$1

# 输出视频文件命名开始的数字，eg: 1234.mp4 -> 1234
outputMp4FileNameStartNum=`cd ${outputMp4FilePath} && ls | grep -E '[0-9]+.mp4' | awk -F '.' '{print $1}' | sort -rn | head -1`
[ ".${outputMp4FileNameStartNum}" = "." ] && outputMp4FileNameStartNum="0"

# 视频根据文件大小拆成每 10M 一个小视频，这里计算拆分数量
num=$(expr $(du -sm ${inputMp4FilePath}/${inputMp4FileName}  | awk '{print $1}') / 10)
if [ "${num}" = "0" ]
then
echo "${inputMp4FilePath}/${inputMp4FileName} less than 10M, removing ..."
rm -f ${inputMp4FilePath}/${inputMp4FileName}
return 1
fi

# 视频小时格式时长打印
endTime=$(ffmpeg -i ${inputMp4FilePath}/${inputMp4FileName} 2>&1 | grep 'Duration' | cut -d ' ' -f 4 | sed s/,//)

# 视频秒格式时长打印
seconds=$(ffprobe -v quiet -select_streams v -show_entries stream=duration -of csv="p=0" ${inputMp4FilePath}/${inputMp4FileName} | awk -F '.' '{print $1}')

# 计算拆分后的每个视频时长（秒)
interval=`expr ${seconds} / ${num}`

start_time_seonds="0"
start_time="00:00:00"

n=0
outputMp4FileNameNum=${outputMp4FileNameStartNum}
while :
do
((n++))
((outputMp4FileNameNum++))
end_time_seonds=`expr ${start_time_seonds} + ${interval}`
end_time=`secondsTotime ${end_time_seonds}`
[ "$n" -gt "$num" ] && break
outputMp4FileName="${outputMp4FileNameNum}.mp4"
echo "produce ${start_time} - ${end_time} -> ${outputMp4FileName} ..."
ffmpeg -ss ${start_time} -t ${end_time} -y -i ${inputMp4FilePath}/${inputMp4FileName} -vcodec copy -acodec copy ${outputMp4FilePath}/${outputMp4FileName} &> /var/log/ffmpeg.log || exit 1
start_time_seonds=${end_time_seonds}
start_time=${end_time}
done

echo "end produce ${start_time} - ${end_time} -> ${outputMp4FileName} ..."

}

main() {

# 检查 ffmpeg
! which ffmpeg &> /dev/null && echo "Install ffmpeg first !" && exit 1

# 输入视频输入路径
inputMp4FilePath=$1
[ ! -d ${inputMp4FilePath} ] && echo "There is no ${inputMp4FilePath}, Please check first ..." && exit 1

# 视频文件输出路径
outputMp4FilePath=$2
mkdir -p ${outputMp4FilePath}

# 拆分视频文件输出路径
sourceMp4FilePath="${outputMp4FilePath}"
mkdir -p ${sourceMp4FilePath}

# 开始循环制造视频文件
for i in `ls ${inputMp4FilePath} | grep -E '*.mp4'`
do
echo "ffmpeg ${i} ... "
produceMp4File ${i}
done

}

main $@
