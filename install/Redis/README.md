## 常用操作

* **配置密码**

``` shell
# 查看当前环境是否配置过密码
## 如下返回则说明未配置密码
redis-cli -h 127.0.0.1 -p 6397
127.0.0.1:6379> keys *
(empty list or set)
## 如下返回则说明已经配置了密码
redis-cli -h 127.0.0.1 -p 6397
127.0.0.1:6379> keys *
(error) NOAUTH Authentication required.

# 手动配置 redis.conf 的 requirepass 的值为密码（P@ssword）
...
requirepass P@ssword
...
```

* **开放远程连接**

``` shell
# 手动修改 redis.conf 的 bind 127.0.0.1 的值为 bind 0.0.0.0
...
bind 0.0.0.0
...
bind 127.0.0.1
