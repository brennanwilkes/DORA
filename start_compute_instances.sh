#!/usr/bin/env bash

REPO="$1"
USER="$2"
IP="$3"
KEY="$4"
DATA_FILE="~/$REPO/authDataFile.txt"
DATA=$( eval cat $DATA_FILE )

echo "Please run:"

i=0
while IFS="\n" read -r worker; do
	IP=$( echo "$worker" | cut -d',' -f1 )
	USER=$( echo "$worker" | cut -d',' -f2 )
	KEY=$( echo "$worker" | cut -d',' -f3 )
	ssh -o StrictHostKeyChecking=no -i "$KEY" "$USER@$IP" "cd ~/$REPO && nohup ./worker_study.sh '$i' '$USER' '$IP' '$KEY' >/dev/null 2>/dev/null </dev/null &"
	i=$(( $i + 1 ))
done <<< "$DATA"
