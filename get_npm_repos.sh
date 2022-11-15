#!/usr/bin/env bash

URL="https://gist.githubusercontent.com/anvaka/8e8fa57c7ee1350e3491/raw/b6f3ebeb34c53775eea00b489a0cea2edd9ee49c/03.pagerank.md"

NPM=$( curl -Ls "$URL" | grep -o '\(https://www.npmjs.org/package/[^)]*\)' | grep -v '@types' )
NPM_BASE="https://registry.npmjs.com"

for package in $NPM
do
	name=$( echo "$package" | rev | cut -d'/' -f1 | rev )
	REPO=$( curl -Ls "$NPM_BASE/$name" | node parse_pr_commit_json.js 10 | grep -Eo 'github.com/[^/]+/[^/]+' | sed 's/github.com\///g' | sed 's/\.git.*$//g')
	echo "$REPO"
done
