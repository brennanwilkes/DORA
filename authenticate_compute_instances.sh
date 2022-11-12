#!/usr/bin/env bash

REPO="$1"
DATA_FILE="~/$REPO/authDataFile.txt"

while IFS= read -r worker; do
	IP=$( echo "$worker" | cut -d',' -f1 )
	USER=$( echo "$worker" | cut -d',' -f2 )
	KEY=$( echo "$worker" | cut -d',' -f3 )
	ssh -i "$KEY" "$USER@$IP" "cd ~/$REPO && gh auth status || gh auth login"
done < "$DATA_FILE"
