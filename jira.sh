#!/usr/bin/env bash

JIRA_URL="$1"
JIRA_PROJECT="$2"

curl -s -X GET -H "Content-Type: application/json" "https://$JIRA_URL/rest/api/3/search?jql=project%20%3D%20\"$JIRA_PROJECT\"%20AND%20resolution%20%3D%20\"Done\"%20AND%20fixVersion%20in%20releasedVersions()%20AND%20type%20%3D%20\"Bug\"%20AND%20status%20%3D%20\"Closed\"%20ORDER%20BY%20created%20DESC" --user "$JIRA_USER:$JIRA_TOKEN"
