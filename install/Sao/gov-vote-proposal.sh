#!/usr/bin/env bash

#
# 2023/06/15
# xiechengqi
# gov vote sao proposal
#

main() {

export PROPOSAL_ID=${1}
[ ".${PROPOSAL_ID}" = "." ] && echo "proposal id is null, exit ..." && exit 1
export PROPOSAL_VOTE=${2-"yes"}
export SAO_HOME=${3-"/root/.sao"}
! saod --home ${SAO_HOME} query gov proposal ${PROPOSAL_ID} && echo "Can not find proposal ${PROPOSAL_ID}, exit ..." && exit 1
export validatorAddress=$(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Cosmos/get-local-validator-address.sh | bash -s saod ${SAO_HOME} | awk '{print $NF}')
[ ".${validatorAddress}" = "." ] && echo "Can not find validator address, exit ..." && exit 1
echo "echo y | saod --home ${SAO_HOME} tx gov vote ${PROPOSAL_ID} ${PROPOSAL_VOTE} --from ${validatorAddress}"
echo y | saod --home ${SAO_HOME} tx gov vote ${PROPOSAL_ID} ${PROPOSAL_VOTE} --from ${validatorAddress}

}

main $@
