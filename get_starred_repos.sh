#!/usr/bin/env bash

URL="https://raw.githubusercontent.com/EvanLi/Github-Ranking/master/Top100/"
LANGS="C|CPP|Go|Java|JavaScript|PHP|Python|Rust|Swift|TypeScript"

IFS="|"
for lang in $LANGS
do
	REPOS=$( curl -Ls "${URL}${lang}.md" | grep -Eo '\(https://github.com/[^/]+/[^/)]+' | sed 's/(https:\/\/github.com\///g' | sed 's/\.git.*$//g' )

	echo "$REPOS"
done
