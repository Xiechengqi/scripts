#!/usr/bin/env bash

main() {

[ ".${TAAPI_API_KEY}" = "." ] && read -p "TAAPI_API_KEY(https://taapi.io/my-account/): " TAAPI_API_KEY
[ ".${TAAPI_API_KEY}" = "." ] && echo "TAAPI_API_KEY 不可以为空，退出 ..." && exit 1 || echo "export TAAPI_API_KEY=\"${TAAPI_API_KEY}\"" >> ~/.profile

export TOKEN=$(echo ${1} | awk -F '=' '{print $NF}' | awk -F 'USDT' '{print $1}')
[ "$(curl -SsL https://api.binance.com/api/v3/ticker/price?symbol=${TOKEN}USDT | jq -r .symbol)" != "${TOKEN}USDT" ] && echo "Binance 找不到 ${TOKEN}USDT 交易对，请检查 ..." && exit 1

cat << EOF

===== ${TOKEN} 市场行情 =====
$(curl -SsL https://fapi.binance.com/fapi/v1/premiumIndex?symbol=${TOKEN}USDT)
下面数组数据: {最老 -> 最新}
1分钟线 EMA20: $(curl -SsL "https://api.taapi.io/ema?secret=${TAAPI_API_KEY}&exchange=binance&symbol=${TOKEN}/USDT&interval=1m&period=20&results=10" | jq -rc .value)
1分钟线 RSI7: $(curl -SsL "https://api.taapi.io/rsi?secret=${TAAPI_API_KEY}&exchange=binance&symbol=${TOKEN}/USDT&interval=1m&period=7&results=10" | jq -rc .value)
1分钟线 RSI14: $(curl -SsL "https://api.taapi.io/rsi?secret=${TAAPI_API_KEY}&exchange=binance&symbol=${TOKEN}/USDT&interval=1m&period=14&results=10" | jq -rc .value)
4小时线 EMA20: $(curl -SsL "https://api.taapi.io/ema?secret=${TAAPI_API_KEY}&exchange=binance&symbol=${TOKEN}/USDT&interval=4h&period=20&results=10" | jq -rc .value)
4小时线 RSI7: $(curl -SsL "https://api.taapi.io/rsi?secret=${TAAPI_API_KEY}&exchange=binance&symbol=${TOKEN}/USDT&interval=4h&period=7&results=10" | jq -rc .value)

EOF

}

main $@
