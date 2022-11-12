#!/usr/bin/env bash

REPO="$1"
DATA_FILE="~/$REPO/authDataFile.txt"
DATA=$( eval cat $DATA_FILE )

while IFS="\n" read -r worker; do
	IP=$( echo "$worker" | cut -d',' -f1 )
	USER=$( echo "$worker" | cut -d',' -f2 )
	KEY=$( echo "$worker" | cut -d',' -f3 )
	echo ssh -i "$KEY" "$USER@$IP" "cd ~/$REPO && gh auth status || gh auth login"
	ssh -i "$KEY" "$USER@$IP" "cd ~/$REPO && gh auth status || gh auth login"
done <<< "$DATA"
