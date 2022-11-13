#!/usr/bin/env bash

WORKER_ID="$1"
USER="$2"
REMOTE="$3"
KEY="$4"

touch I_HAVE_STARTED

PATH="/home/ubuntu/.nvm/versions/node/v18.3.0/bin:$PATH" LC_ALL=C ./study.sh config.json > stdout.txt
scp -o StrictHostKeyChecking=no -i "$KEY" stdout.txt "$USER@$REMOTE:~/$WORKER_ID-stdout.txt"
scp -o StrictHostKeyChecking=no -i "$KEY" log "$USER@$REMOTE:~/$WORKER_ID-log"
scp -o StrictHostKeyChecking=no -i "$KEY" results.json "$USER@$REMOTE:~/$WORKER_ID-results.json"

touch I_HAVE_COMPLETED
