#!/usr/bin/env bash

#
# 2021/12/03
# 根据关键词下载 Bilibili 视频
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/video/download_video.sh | sudo bash -s [关键词] [保存视频目录路径] [下载视频总量大小(G)]
# bash download_bilibili_video.sh [关键词] [保存视频目录路径] [下载视频总量大小(G)]
#

trap "_clean" EXIT

_clean() {
cd /tmp && rm -f $$_*
}

main() {

# bilibili 搜索关键词
keyword=$1
# 视频文件保存目录路径
videoPath=$2 && mkdir -p $videoPath
# 视频文件总量大小，单位G
videoSize=$3
# 搜索页数
pageNum="1"

# 检查下载工具
! which annie &> /dev/null && echo "Please install annie first !" && exit 1

# 检查 jq
! which jq &> /dev/null && echo "Please install jq first !" && exit 1

while :
do

# 计算视频目录当前大小，单位G
videoNowSize=`expr $(du -sm ${videoPath} | awk '{print $1}') / 1024`
echo "${videoPath} size: ${videoNowSize}G"
# 若达到总量大小则退出下载循环
[ "${videoNowSize}" -ge "${videoSize}" ] && break

# 获取视频下载链接列表
curl -SsL 'https://api.bilibili.com/x/web-interface/search/type?page='"${pageNum}"'&order=totalrank&duration=4&keyword='"${keyword}"'&search_type=video' | jq -r .data.result[].arcurl > /tmp/$$_downloadUrl

while read url
do
annie -m -O $(date +%s) -o ${videoPath} ${url}
# 计算视频目录当前大小，单位G
videoNowSize=`expr $(du -sm ${videoPath} | awk '{print $1}') / 1024`
echo "${videoPath} size: ${videoNowSize}G"
# 若达到总量大小则退出下载循环
[ "${videoNowSize}" -ge "${videoSize}" ] && exit 0
done < /tmp/$$_downloadUrl

# 搜索页数自增1
((pageNum++))

done

}

main $@
