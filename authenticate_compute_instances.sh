#!/usr/bin/env bash

DATA_FILE="./authDataFile.txt"
REPO="$( pwd | rev | cut -d'/' -f1 | rev )"

while IFS= read -r worker; do
	IP=$( echo "$worker" | cut -d',' -f1 )
	USER=$( echo "$worker" | cut -d',' -f2 )
	KEY=$( echo "$worker" | cut -d',' -f3 )
	ssh -i "$KEY" "$USER@$IP" "cd ~/$REPO && gh auth status || gh auth login"
done < "$DATA_FILE"
