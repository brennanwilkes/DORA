#!/usr/bin/env bash
ROOT="$(pwd)"
REPO="$1"
BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | grep -i bug | cut -d'	' -f1 )

for label in $BUG_LABELS
do
	ISSUES=$( gh issue list --repo "$REPO" -l "$label" -L 1000 --search "is:closed" | cut -d'	' -f1 )
	for issue in $ISSUES
	do
		pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" | grep -Eo 'pull/[0-9]{1,4}' | sort | uniq | cut -d '/' -f2 )
		for pull_request in $pull_requests
		do
			sha=$( gh api "/repos/$REPO/pulls/$pull_request/commits" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 1 2>/dev/null )
			date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
			[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && {
				echo "$issue,$pull_request,$sha,$date"
				cat "$ROOT/balena-results.json" | grep "$sha" >/dev/null && echo "HIT!!! ($sha)"
			}
		done
	done
	wait
done
