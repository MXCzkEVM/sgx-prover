#! /bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${SCRIPT_DIR}

#
CONFIG_FILE=../config/moonchain.json

#
NETWORK="moonchain_geneva"
L1_NETWORK="arbitrum_sepolia"
PROVER_MANAGER_URL="https://geneva-prover-manager.moonchain.com"

# Read config file
if [ -e ${CONFIG_FILE} ]; then
    SGX_INSTANCE_ID=$(jq .instanceId ${CONFIG_FILE})
    echo "Instane ID: ${SGX_INSTANCE_ID}"
fi

#
echo "Network: ${NETWORK} / ${L1_NETWORK}"

export NETWORK=${NETWORK}
export L1_NETWORK=${L1_NETWORK}
export PROVER_MANAGER_URL=${PROVER_MANAGER_URL}
docker compose up raiko moonchain_prover_agent -d