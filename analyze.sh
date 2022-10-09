#!/usr/bin/env bash


REPO="brnkl/BRNKL-functions"

# 0 = release
#TODO: Actions
DEPLOYMENT=0
START="Oct 10 2022"
END="Jan 01 2019"

############

WORKING_DIR="$(pwd)/temp"

#####

gh auth status || gh auth login
#gh auth login


[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
gh repo clone "$REPO" "$WORKING_DIR"
cd "$WORKING_DIR"

# rm -rf "$WORKING_DIR"
