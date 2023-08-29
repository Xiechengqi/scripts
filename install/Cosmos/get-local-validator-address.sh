#!/usr/bin/env bash

main() {

export BINARY_NAME="$1"
[ ".${BINARY_NAME}" = "." ] && echo "Usage: bash get-local-validator-address.sh [BINARY_NAME]" && exit 1

validatorWalletAddress =$(${BINARY_NAME} debug addr $(curl -SsL http://localhost:26657/status | jq -r .result.node_info.id) | grep 'Bech32 Acc' | awk '{print $NF}')
echo "${BINARY_NAME} Local Validator Wallet Address: ${validatorWalletAddress}"

}

main $@
