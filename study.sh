#!/usr/bin/env bash

echo "====================================================================================================================================" >>log
echo "Launcing study..." >>log

gh auth status >>log 2>>log || gh auth login

[[ -f ".env" ]] && {
	eval $( cat .env | grep '^[^#]' | xargs -n1 echo export )
}

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
