#!/usr/bin/env bash

WORKER_ID="$1"
USER="$2"
REMOTE="$3"
KEY="$4"

touch I_HAVE_STARTED

./study.sh config.json > stdout.txt
scp -i "$KEY" stdout.txt "$USER@$REMOTE:~/$WORKER_ID-stdout.txt"
scp -i "$KEY" log "$USER@$REMOTE:~/$WORKER_ID-log"
scp -i "$KEY" results.json "$USER@$REMOTE:~/$WORKER_ID-results.json"

touch I_HAVE_COMPLETED
