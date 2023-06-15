#!/usr/bin/env bash

main() {

export BINARY_NAME="$1"
[ ".${BINARY_NAME}" = "." ] && echo "Usage: bash get-local-validator-address.sh [BINARY_NAME] [(ROOT_HOME)]" && exit 1
export ROOT_HOME="$2"
[ ".${ROOT_NAME}" = "." ] && echo "Usage: bash get-local-validator-address.sh [BINARY_NAME] [(ROOT_HOME)]" && exit 1
export validatorInfoPubKeyValue=$(${BINARY_NAME} --home ${ROOT_HOME} status | awk -F 'value":"' '{print $NF}' | awk -F '"' '{print $1}')
export validatorOperatorAddress=$(${BINARY_NAME} --home ${ROOT_HOME} query staking validators | grep -A 20 "${validatorInfoPubKeyValue}" | grep 'operator_address:' | head -1 | awk '{print $NF}')
export validatorWalletAddress=""

for address in `${BINARY_NAME} --home ${ROOT_HOME} keys list | grep 'address:' | awk '{print $NF}'`
do
echo $(${BINARY_NAME} --home ${ROOT_HOME} keys show --address ${address} --bech=val) | grep "${validatorOperatorAddress}" &> /dev/null && validatorWalletAddress="${address}" && break
done
echo "${BINARY_NAME} Local Validator Wallet Address: ${validatorWalletAddress}"

}

main $@
