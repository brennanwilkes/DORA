#!/usr/bin/env bash

# eval "$( cat .env )"

REPO="brnkl/BRNKL-functions"
URL="https://github.com/$REPO"
# URL_AUTH="https://$GH_NAME:$GH_TOKEN@github.com/$REPO"

# curl -fsS "https://api.github.com/repos/$REPO" 2>/dev/null >/dev/null && IS_PRIVATE=0 || {
# 	URL="$URL_AUTH"
# 	IS_PRIVATE=1
# }

# 0 = release
#TODO: Actions
DEPLOYMENT=0
START="Oct 10 2022"
END="Jan 01 2019"

############


WORKING_DIR="$(pwd)/temp"

git clone "$URL" "$WORKING_DIR"
cd "$WORKING_DIR"

# rm -rf "$WORKING_DIR"
