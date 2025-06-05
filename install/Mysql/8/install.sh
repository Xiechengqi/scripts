#!/usr/bin/env bash

#
# xiechengqi
# 2025/05/30
# install mysql 8.0 5.7
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Mysql/8/install.sh | sudo bash
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# check os
export osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22"

# envrionments
export serviceName="mysql"
export installPath="/data/${serviceName}"
export version="8.0"
[ "${countryCode}" = "China" ] && export downloadUrl="https://mirrors.aliyun.com/mysql/MySQL-8.0/mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz" || export downloadUrl="https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz"
export xtrabackupDownloadUrl="https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/tarball/percona-xtrabackup-8.0.28-21-Linux-x86_64.glibc2.17.tar.gz"
export mysqlPort="3306"
export password="EwFjfhMj%8"
export initDbName=""
export initUserName=""
export initUserPassword=""

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# create mysql user and group
! grep mysql /etc/group &> /dev/null && EXEC "groupadd mysql"
! grep mysql /etc/passwd &> /dev/null && EXEC "useradd -r -s /bin/false -g mysql mysql"

# install requirements
EXEC "apt update && apt install -y libncurses5"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{xtrabackup,mysql-server,conf,data,logs,run,tmp,mysql-bin,relay-logs}"

# download mysql
EXEC "rm -f /tmp/mysql.tar.xz"
INFO "wget ${downloadUrl} -O /tmp/mysql.tar.xz" && wget ${downloadUrl} -O /tmp/mysql.tar.xz || exit 1
EXEC "tar xvJf /tmp/mysql.tar.xz --strip-components 1 -C ${installPath}/mysql-server/"

# download xtrabackup
EXEC "rm -f /tmp/xtrabackup.tar.gz"
INFO "wget ${xtrabackupDownloadUrl} -O /tmp/xtrabackup.tar.gz" && wget ${xtrabackupDownloadUrl} -O /tmp/xtrabackup.tar.gz|| exit 1
EXEC "tar -zxvf /tmp/xtrabackup.tar.gz --strip-components 1 -C ${installPath}/xtrabackup"
EXEC "chown -R mysql:mysql ${installPath}/xtrabackup"

# register bin
sed -i '/mysql-server/d' /etc/profile
echo "export PATH=${installPath}/mysql-server/bin:${installPath}/xtrabackup/bin:\$PATH" >> /etc/profile
INFO "tail -1 /etc/profile" && tail -1 /etc/profile
EXEC "source /etc/profile"
INFO "mysql -V" && mysql -V
INFO "xtrabackup --version" && xtrabackup --version

# config
cat > ${installPath}/conf/my.cnf << EOF
[client]
port=${mysqlPort}
default-character-set=utf8mb4
socket=${installPath}/run/mysql.sock

[mysql]
#设置mysql客户端默认字符集
default-character-set=utf8mb4
#在mysql提示符中显示当前用户、数据库、时间等信息
prompt="\\u@\\h [\\d]>"
#不使用自动补全功能
no-auto-rehash

[mysqld]
bind-address=0.0.0.0
port=${mysqlPort}
user=mysql
server-id=36

#time zone
default-time-zone=SYSTEM
log_timestamps=SYSTEM

#设置mysql的安装目录
basedir=${installPath}/mysql-server

#设置mysql数据库的数据的存放目录
datadir=${installPath}/data

#连接数
max_connections=5000
max_connect_errors=10000

#定义sock文件
socket=${installPath}/run/mysql.sock
pid_file=${installPath}/run/mysqld.pid

#定义打开最大文件数
open_files_limit=65535

#服务端使用的字符集默认为UTF8
character-set-server=utf8mb4

#创建新表时将使用的默认存储引擎
default-storage-engine=INNODB

#默认使用mysql_native_password插件认证
default_authentication_plugin=mysql_native_password

#是否对sql语句大小写敏感，1表示不敏感
lower_case_table_names=1

#关闭dns解析
skip_name_resolve=1

#开启gtid模式
gtid-mode=on
enforce-gtid-consistency=1

#MySQL连接闲置超过一定时间后(单位：秒)将会被强行关闭
#MySQL默认的wait_timeout  值为8个小时, interactive_timeout参数需要同时配置才能生效
interactive_timeout=28800
wait_timeout=28800

#Metadata Lock最大时长(秒),一般用于控制 alter操作的最大时长sine mysql5.6
#执行 DML操作时除了增加innodb事务锁外还增加Metadata Lock，其他alter(DDL)session将阻塞
lock_wait_timeout=3600
#内部内存临时表的最大值
#比如大数据量的group by ,order by时可能用到临时表，
#超过了这个值将写入磁盘，系统IO压力增大
tmp_table_size=64M
max_heap_table_size=64M

###### slow log ######
#slow存储方式
log-output=file
#开启慢查询日志记录功能
slow_query_log=1
#慢日志记录超过1秒的SQL执行语句,可调小到0.1秒
long_query_time=1
#慢日志文件
slow_query_log_file=${installPath}/logs/mysql-slow.log
#记录由Slave所产生的慢查询
#log-slow-slave-statements=1
#开启DDL等语句慢记录到slow log
log_slow_admin_statements=1
#记录没有走索引的查询语句
log_queries_not_using_indexes =1
#表示每分钟允许记录到slow log的且未使用索引的SQL语句次数
log_throttle_queries_not_using_indexes=60
#查询检查返回少于该参数指定行的SQL不被记录到慢查询日志
min_examined_row_limit=100

#错误日志
log_error_verbosity=3
log_error=${installPath}/logs/error.log

#一般日志开启,默认关闭
general_log=on
#一般日志文件路径
general_log_file=${installPath}/logs/query.log

####### binlog ######
##binlog 格式
binlog_format=row
##binlog 1 天自动过期删除
binlog_expire_logs_seconds=86400
##binlog文件
log-bin=${installPath}/mysql-bin/mysql-${mysqlPort}-bin
##binlog的cache大小
binlog_cache_size=4M
##binlog 能够使用的最大cache
max_binlog_cache_size=2G
##最大的binlog file size
max_binlog_size=1G
##当事务提交之后，MySQL不做fsync之类的磁盘同步指令刷新binlog_cache中的信息到磁盘,而让Filesystem自行决定什么时候来做同步,注重binlog安全性可以设为1
sync_binlog=0

##procedure
log_bin_trust_function_creators=1
##保存bin log的天数
expire_logs_days=14

#限制mysqld的导入导出只能发生在/tmp/目录下
secure_file_priv="${installPath}/tmp/"

#relay log
#复制进程就不会随着数据库的启动而启动
skip_slave_start=1
#relay log的最大的大小
max_relay_log_size=128M
#SQL线程在执行完一个relay log后自动将其删除
relay_log_purge=1
#relay log受损后,重新从主上拉取最新的一份进行重放
relay_log_recovery=1
#relay log文件
relay-log=${installPath}/relay-logs/relay-bin
relay-log-index=${installPath}/relay-logs/relay-bin.index
#开启slave写realy log到binlog中
log_slave_updates
#开启relay log自动清理,如果是MHA架构,需要关闭
relay-log-purge=1

#设置relay log保存在mysql表里面
master_info_repository=TABLE
relay_log_info_repository=TABLE

[mysqldump]
quick
max_allowed_packet=32M

[xtrabackup]
socket=${installPath}/run/mysql.sock'
EOF
EXEC "rm -f /etc/my.cnf && ln -fs /data/mysql/conf/my.cnf /etc/my.cnf"

# chown
EXEC "chown -R mysql.mysql ${installPath}"

# init
EXEC "${installPath}/mysql-server/bin/mysqld --defaults-file=${installPath}/conf/my.cnf --user=mysql --lower-case-table-names=1 --basedir=${installPath}/mysql-server --datadir=${installPath}/data --initialize-insecure"

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/mysql-server/bin/mysqld --defaults-file=\${installPath}/conf/my.cnf --user=mysql &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=MySQL ${version}
Documentation=https://dev.mysql.com/

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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# sleep
sleep 5

# change root password
EXEC "mysqladmin -uroot password ${password}"

# open remote connect
cat > /tmp/mysql-init.sql << EOF
CREATE USER 'root'@'%' IDENTIFIED BY '${password}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
$([ ".${initDbName}" != "." ] && echo "CREATE DATABASE ${initDbName};")
$([ ".${initUserName}" != "." ] && [ ".${initUserPassword}" != "." ] && echo -e "CREATE USER '${initUserName}'@'%' IDENTIFIED BY '${initUserPassword}';\nGRANT ALL PRIVILEGES ON *.* TO '${initUserName}'@'%' WITH GRANT OPTION;")
FLUSH PRIVILEGES;
EOF
INFO "cat /tmp/mysql-init.sql" && cat /tmp/mysql-init.sql
EXEC "mysql -uroot -p${password} < /tmp/mysql-init.sql"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "${serviceName} port: ${mysqlPort}"
YELLOW "connection cmd: mysql -uroot -P${mysqlPort} -p${password}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
