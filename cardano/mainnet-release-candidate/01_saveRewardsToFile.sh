#!/bin/bash

# Script is brought to you by ATADA_Stakepool, Telegram @atada_stakepool

#load variables from common.sh
#       socket          Path to the node.socket (also exports socket to CARDANO_NODE_SOCKET_PATH)
#       genesisfile     Path to the genesis.json
#       magicparam      TestnetMagic parameter
#       cardanocli      Path to the cardano-cli executable
#       cardanonode     Path to the cardano-node executable
. "$(dirname "$0")"/00_common.sh

#Check the commandline parameter
if [[ $# -eq 1 && ! $1 == "" ]]; then addrName=$1; else echo "ERROR - Usage: $0 <AdressName or HASH>"; exit 2; fi

#Check if Address file doesn not exists, make a dummy one in the temp directory and fill in the given parameter as the hash address
if [ ! -f "$1.addr" ]; then echo "$1" > ${tempDir}/tempAddr.addr; addrName="${tempDir}/tempAddr"; fi

checkAddr=$(cat ${addrName}.addr)

typeOfAddr=$(get_addressType "${checkAddr}")

rewardsAmount=$(${cardanocli} shelley query stake-address-info --address ${checkAddr} --cardano-mode ${magicparam} | jq -r "flatten | .[0].rewardAccountBalance")
adaLovelaces=1000000

lastRewardsADA=$(cat ${addrName}lastRewards.txt)
newRewardsADA=`echo "scale=6;$rewardsAmount / $adaLovelaces" | bc`
rewardsADA=`echo "scale=6;$newRewardsADA - $lastRewardsADA" | bc`

echo "scale=6;$rewardsAmount / $adaLovelaces" | bc > "${addrName}"lastRewards.txt

#Is it a Stake Address?
if [[ ${typeOfAddr} == ${addrTypeStake} ]]; then  #Staking Address

        #Checking about rewards on the stake address
        if [[ ${rewardsAmount} == 0 ]]; then echo -e "\e[35mNo rewards found on the stake Addr !\e[0m\n";
        elif [[ ${rewardsAmount} == null ]]; then echo -e "\e[35mStaking Address is not on the chain, register it first !\e[0m\n";
        else current_time=$(date "+%Y-%m-%dT%H:%M:%S")
        echo "deposit,incoming,$rewardsADA,ADA,finished,$current_time"
        echo "deposit,incoming,$rewardsADA,ADA,finished,$current_time" >> "${addrName}"rewards.csv
        fi

else #unsupported address type

        echo -e "\e[35mAddress type unknown!\e[0m";
fi