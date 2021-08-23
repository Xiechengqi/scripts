## 0、测试环境

## 1、全节点部署

* 全节点可以通过不同的客户端实现，常用于搭建比特币全节点的客户端有 bitcoin
* 全节点同步的链可分为: 主链和测试链。对于部署而言，就是启动参数有所差异

| 同步链 | 区块链浏览器 | 说明 |
| --- | --- | --- |
| Mainnet | https://btc.bitaps.com/ | 主链 |
| testnet | https://tbtc.bitaps.com/ | 测试链 

### 1.1 bitcoin 搭建全节点

> * https://github.com/bitcoin/bitcoin

| 端口 | 用途 |
| :--- | :--- |
| 18332(testnet) \| 8332(mainnet) | RPC |
| 18333(testnet) \| 8333(mainnet) | P2P |

## 2、索引部署

> * https://github.com/bitpay/bitcore

| 端口 | 用途 |
| :--- | :--- |
| 3000 | http |

* 由于 BTC 地址模型采用 UTXO(即在钱包导入目标地址的前提下，节点只保存地址的所有交易记录)，所以通过节点无法直接读取地址余额。需要遍历 UTXO 列表进行累加计算出余额
* 所以开源项目 bitcore 诞生，bitcore 是基于 nodejs 开发的提供开源的扫链、钱包、区块浏览器等综合服务
* 索引 API 文档 - https://github.com/bitpay/bitcore/blob/master/packages/bitcore-node/docs/api-documentation.md

## 3、常用操作

``` shell
# bitcoin-cli [-testnet] [-conf=自定义配置文件路径] xxx
# 指定 conf
alias bitcoin-cli='bitcoin-cli -conf=/data/BTC/bitcoin/conf/bitcoin.conf'

# GETH API 查看快高(用户:bitcorenodetest 密码: local321)
curl --user bitcorenodetest --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:18332/

# 索引 API 查看块高
curl -v localhost:3000/api/BTC/mainnet/block/tip
curl -v localhost:3000/api/BTC/testnet/block/tip

# 查看当前同步的快高
bitcoin-cli getblockcount

# 查看区块链信息：如同步进度
bitcoin-cli getblockchaininfo

# 查看所有命令
bitcoin-cli help

# 获得比特币核心客户端状态的信息
bitcoin-cli getinfo

# 显示钱包当前的所有地址的余额总和
bitcoin-cli getbalance

# 查看网络状态
bitcoin-cli getnetworkinfo

# 查看网络节点
bitcoin-cli getpeerinfo
```
