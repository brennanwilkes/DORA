#!/usr/bin/env bash

# gh auth status >/dev/null 2>/dev/null || gh auth login

eval $( cat .env | grep '^[^#]' |xargs -n1 echo export )

cat "$1" | tr -d '\n' | tr -d ' ' | tr -d '\t' | grep -Eo "failures[^}]*}" | grep -o 'type[^,]*0,' >/dev/null && {
	#Using JIRA failure mode
	[[ -z "$JIRA_USER" ]] && {
		echo "Please set 'JIRA_USER' as an env variable or via the .env file"
		exit 1
	}
	[[ -z "$JIRA_TOKEN" ]] && {
		echo "Please set 'JIRA_TOKEN' as an env variable or via the .env file"
		exit 1
	}
}

node dispatcher.js "$1" 
