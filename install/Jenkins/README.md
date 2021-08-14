* docker 安装

``` shell

```

* docker 升级

``` shell
# 下载最新的 jenkins.war

# 用最新的 jenkins.war 替换启动容器 jenkins 内的 jenkins.war
docker copy ./jenkins.war jenkins:/usr/share/jenkins/

# 页面访问 jenkins 重启地址 https://jenkins.xiechengqi.top/restart
# 点击确认，重启后即完成升级
```
