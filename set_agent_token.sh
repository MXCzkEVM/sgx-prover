#! /bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${SCRIPT_DIR}

#
CONFIG_FILE=../config/moonchain.json

# Read config file
if [ "_$1" == "_" ]; then
    echo "Missing arg1."
    echo "Example: $basename($0) 0x0123456789ABCDEF0123456789ABCDEF01234567"
    exit 1
elif [ ! -e ${CONFIG_FILE} ]; then
    echo "${CONFIG_FILE} not found."
    exit 1
else
    NEW_CFG=$(jq -cM ".agentToken = \"$1\"" ${CONFIG_FILE})
    echo ${NEW_CFG} > ${CONFIG_FILE}
fi
