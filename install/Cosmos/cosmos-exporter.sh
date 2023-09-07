#!/usr/bin/env bash

#
# 2023/09/07
# xiechengqi
# monitor cosmos-like consensus node info
#

trap "_clean" EXIT

_clean() {
cd /tmp/ && rm -f $$*
}


function check_rpc() {
local rpc="$1"
if [ "$(curl -SsL ${rpc}/status 2>/dev/null | jq -r .result.sync_info.catching_up)" = "false" ]
then
return 0
else
exit 1
fi
}

function check_api() {
local api="$1"
if [ "$(curl -SsL ${api}/cosmos/base/tendermint/v1beta1/syncing 2>/dev/null | jq -r .syncing)" = "false" ]
then
return 0
else
exit 1
fi
}


function prom_metric() {
local metric="$1"
local content="$2"
local value="$3"
cat >> /tmp/$$.prom << EOF
${metric}{${content}} ${value}
EOF

}

function format_metric() {

sort /tmp/$$.prom > /tmp/$$_sort.prom && mv /tmp/$$_sort.prom /tmp/$$.prom

for metric in $(cat /tmp/$$.prom | awk -F '{' '{print $1}' | sort | uniq)
do

cat << EOF
# HELP ${metric} get $(echo ${metric} | tr '_' ' ')
# TYPE ${metric} gauge
$(grep -E "^${metric}{" /tmp/$$.prom)
EOF

done

}

function chain_basic_info() {

local rpc=${public_rpc}
local api=${public_api}
local chain_info=${chain_info}
local chain_validators_number=$(curl -SsL ${rpc}/validators | jq -r .result.total)

prom_metric chain_latest_block_height ${chain_info} ${chain_latest_block_height}
prom_metric chain_validators_number ${chain_info} ${chain_validators_number}

for line in $(curl -SsL ${rpc}/genesis | jq -r '.result.genesis.app_state.slashing.params | "signed_blocks_window=" + .signed_blocks_window, "min_signed_per_window=" + .min_signed_per_window, "downtime_jail_duration=" + .downtime_jail_duration, "slash_fraction_double_sign=" + .slash_fraction_double_sign, "slash_fraction_downtime=" + .slash_fraction_downtime')
do
local ${line}
done

local chain_slash_window=${signed_blocks_window}
local chain_slash_min_window_percent=$(printf "%.1f\n" $(echo "${min_signed_per_window} * 100" | bc))
local chain_slash_jail_times=$(echo ${downtime_jail_duration} | sed 's/s$//')
local chain_slash_jail_percent=$(printf "%.1f\n" $(echo "${slash_fraction_downtime} * 100" | bc))
local chain_slash_double_sign_percent=$(printf "%.1f\n" $(echo "${slash_fraction_double_sign} * 100" | bc))

prom_metric chain_slash_window ${chain_info} ${chain_slash_window}
prom_metric chain_slash_min_window_percent ${chain_info} ${chain_slash_min_window_percent}
prom_metric chain_slash_jail_times ${chain_info} ${chain_slash_jail_times}
prom_metric chain_slash_jail_percent ${chain_info} ${chain_slash_jail_percent}
prom_metric chain_slash_double_sign_percent ${chain_info} ${chain_slash_double_sign_percent}

}

function validator_info() {

local rpc=${public_rpc}
local api=${public_api}
local chain_info=${chain_info}
local validator_address=${1}

for line in $(curl -SsL ${api}/cosmos/staking/v1beta1/validators/${validator_address} | jq -r '.validator | "validator_jailed=" + (.jailed|tostring), "validator_bonded=" + .status, "validator_bonded_tokens=" + .tokens, "validator_pub_key_value=" + .consensus_pubkey.key, "validator_moniker=" + .description.moniker')
do
local ${line}
done

local validators_number=$(curl -SsL ${rpc}/validators | jq -r .result.total)
local validator_pub_key_value_query=$(echo ${validator_pub_key_value} | sed 's/+/\\+/g')
local validator_consensus_address=$(curl -SsL ${api}/cosmos/base/tendermint/v1beta1/validatorsets/latest?pagination.limit=${validators_number} | jq -r --arg validator_pub_key_value_query "$validator_pub_key_value_query" '.validators[] | select(.pub_key.key|test("\($validator_pub_key_value_query)"))' | jq -r .address)
local validator_info="${chain_info},validator_moniker=\"${validator_moniker}\",validator_address=\"${validator_address}\",validator_consensus_address=\"${validator_consensus_address}\""

local validator_jailed_status=$([ "${validator_jailed}" = "false" ] && echo "1" || echo "0")
local validator_bonded_status=$([ "${validator_bonded}" = "BOND_STATUS_BONDED" ] && echo "0" || echo "1")
local validator_bonded_tokens=$(printf "%.1f\n" $(echo "${validator_bonded_tokens} * ${digit}" | bc))
prom_metric validator_jailed_status ${validator_info} ${validator_jailed_status}
prom_metric validator_bonded_status ${validator_info} ${validator_bonded_status}
prom_metric validator_bonded_tokens ${validator_info} ${validator_bonded_tokens}

for line in $(curl -SsL ${api}/cosmos/slashing/v1beta1/signing_infos/${validator_consensus_address} | jq -r '. | "validator_tombstoned=" + (.val_signing_info.tombstoned|tostring), "validator_missed_blocks=" + .val_signing_info.missed_blocks_counter')
do
local ${line}
done
local validator_tombstoned_status=$([ "${validator_tombstoned}" = "false" ] && echo "1" || echo "0")
prom_metric validator_tombstoned_status ${validator_info} ${validator_tombstoned_status}
prom_metric validator_missed_blocks ${validator_info} ${validator_missed_blocks}

local validator_commission_rewards=$(curl -SsL ${api}/cosmos/distribution/v1beta1/validators/${validator_address}/commission | jq -r '.commission.commission[0].amount')
local validator_commission_rewards=$(printf "%.3f\n" $(scale=3;echo "${validator_commission_rewards} * ${digit}" | bc))
local validator_outstanding_rewards=$(curl -SsL ${api}/cosmos/distribution/v1beta1/validators/${validator_address}/outstanding_rewards | jq -r '.rewards.rewards[0].amount')
local validator_outstanding_rewards=$(printf "%.3f\n" $(scale=3;echo "${validator_outstanding_rewards} * ${digit}" | bc))
local validator_self_bond_rewards=$(printf "%.3f\n" $(echo "${validator_outstanding_rewards} - ${validator_commission_rewards}" | bc))

prom_metric validator_commission_rewards ${validator_info} ${validator_commission_rewards}
prom_metric validator_outstanding_rewards ${validator_info} ${validator_outstanding_rewards}
prom_metric validator_self_bond_rewards ${validator_info} ${validator_self_bond_rewards}

}

function fullnode_info() {

local rpc="$1"

for line in $(curl -SsL ${rpc}/abci_info | jq -r '.result.response | "fullnode_version=" + .version, "fullnode_latest_block_height=" + .last_block_height')
do
local ${line}
done

for line in $(curl -SsL ${rpc}/status | jq -r '.result | "chain_id=" + .node_info.network, "fullnode_moniker=" + .node_info.moniker, "fullnode_voting_power=" + .validator_info.voting_power')
do
local ${line}
done

local fullnode_info="chain_id=\"${chain_id}\",fullnode_version=\"${fullnode_version}\",fullnode_moniker=\"${fullnode_moniker}\",fullnode_rpc=\"${rpc}\""
local fullnode_peers_number=$(curl -SsL ${rpc}/net_info | jq -r '.result.n_peers')
local fullnode_if_validator=$([ "${fullnode_voting_power}" -gt "0" ] && echo "0" || echo "1")

prom_metric fullnode_latest_block_height ${fullnode_info} ${fullnode_latest_block_height}
prom_metric fullnode_if_validator ${fullnode_info} ${fullnode_if_validator}
prom_metric fullnode_voting_power ${fullnode_info} ${fullnode_voting_power}
prom_metric fullnode_peers_number ${fullnode_info} ${fullnode_peers_number}

}

main() {

export installPath=${1-"/data/cosmos-exporter"} && mkdir -p ${installPath} /data/metric
! ls ${installPath}/cosmos-exporter.sh &> /dev/null && curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Cosmos/cosmos-exporter.sh -o ${installPath}/cosmos-exporter.sh && chmod +x ${installPath}/cosmos-exporter.sh
source ${installPath}/env &> /dev/null

if [ ".${public_rpc}" = "." ] || [ ".${public_api}" = "." ] || [ ".${digit}" = "." ]
then

read -p "Public RPC: " public_rpc
if check_rpc ${public_rpc}
then
sed -i '/public_rpc/d' ${installPath}/env &> /dev/null
export public_rpc=${public_rpc}
echo "export public_rpc=${public_rpc}" >> ${installPath}/env
fi

read -p "Public API: " public_api
if check_api ${public_api}
then
sed -i '/public_api/d' ${installPath}/env &> /dev/null
export public_api=${public_api}
echo "export public_api=${public_api}" >> ${installPath}/env
fi

read -p "Monitor Chain info?(true/false, default false): " if_monitor_chain
if [ "${if_monitor_chain}" = "true" ]
then
sed -i '/if_monitor_chain/d' ${installPath}/env &> /dev/null
export if_monitor_chain="true"
echo "export if_monitor_chain=\"true\"" >> ${installPath}/env
fi

read -p "digit(Required, eg: 0.000001): " digit
[ ".${digit}" = "." ] && echo "digit can not be empty, exit ..." && exit 1
sed -i '/digit/d' ${installPath}/env &> /dev/null
export digit=${digit}
echo "export digit=${digit}" >> ${installPath}/env

read -p "Monitor Valdiators Address(Default is empty, Multiple separated by commas): " validators
sed -i '/validators/d' ${installPath}/env &> /dev/null
export validators=${validators}
echo "export validators=${validators}" >> ${installPath}/env

read -p "Monitor Fullnodes RPC(Default is empty, Multiple separated by commas): " fullnodes
sed -i '/fullnodes/d' ${installPath}/env &> /dev/null
export fullnodes=${fullnodes}
echo "export fullnodes=${fullnodes}" >> ${installPath}/env

else

check_rpc ${public_rpc}
check_api ${public_api}

fi

for line in $(curl -SsL ${public_rpc}/abci_info | jq -r '.result.response | "latest_version=" + .version, "chain_latest_block_height=" + .last_block_height')
do
export ${line}
done

for line in $(curl -SsL ${public_rpc}/status | jq -r '.result | "chain_id=" + .node_info.network')
do
export ${line}
done

export chain_info="chain_id=\"${chain_id}\",latest_version=\"${latest_version}\""

[ "${if_monitor_chain}" = "true" ] && chain_basic_info

for validator in $(echo ${validators} | tr ',' '\n')
do
validator_info ${validator}
done

for fullnode in $(echo ${fullnodes} | tr ',' '\n')
do
fullnode_info ${fullnode}
done

format_metric

echo && echo '*/3 * * * * '${installPath}'/cosmos-exporter.sh > /data/metric/.'${chain_id}' 2> /dev/null && mv /data/metric/.'${installPath}' /data/metric/'${chain_id}'.prom'

}

main $@
