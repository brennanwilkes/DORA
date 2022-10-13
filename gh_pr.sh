#!/usr/bin/env bash
export ROOT="$(pwd)"
REPO="$1"
CUSTOM_LABELS="$2"

RATE_LIMIT=$( gh api -H "Accept: application/vnd.github+json" "/rate_limit" | node "$ROOT/parse_pr_commit_json" 3 2>/dev/null )

BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | cut -d$'\t' -f1 | grep -i -e "bug" -e "confirm" )
[[ -z "$CUSTOM_LABELS" ]] || {
	CUSTOM_LABELS=$( echo "$CUSTOM_LABELS" | xargs -n1 )
	BUG_LABELS+=$'\n'$(printf '%s' "$CUSTOM_LABELS")
}

waitForGH (){
	REMAINING_QUERIES=$( echo "$1" | cut -d',' -f1 )
	ROLLOVER_TIME=$( echo "$1" | cut -d',' -f2 )
	[[ "$REMAINING_QUERIES" -le 2 ]] && {
		waitTime=$(( "$ROLLOVER_TIME" - "$( date +%s )" ))
		[[ "$waitTime" -gt 0 ]] && sleep "$(( $waitTime + 10 ))"
		gh api -H "Accept: application/vnd.github+json" "/rate_limit" | node "$ROOT/parse_pr_commit_json" 3 2>/dev/null
		exit 0
	}
	echo "$(( $REMAINING_QUERIES - 1 )),$ROLLOVER_TIME"
	exit 0
}

while IFS="\n" read -r label; do
	RATE_LIMIT="$( waitForGH $RATE_LIMIT )"
	ISSUES=$( gh issue list --repo "$REPO" -l "$label" -L 1000 --search "is:closed" | cut -d$'\t' -f1 )
	for issue in $ISSUES
	do
		RATE_LIMIT="$( waitForGH $RATE_LIMIT )"
		pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" | grep -Eo 'pull/[0-9]{1,4}' | sort | uniq | cut -d '/' -f2 )
		RATE_LIMIT="$( waitForGH $RATE_LIMIT )"
		created_at=$( gh api "/repos/$REPO/issues/$issue" | grep -Eo 'created_at[^,]*,' | head -n1 | cut -d':' -f2- | tr -d '"' | tr -d ',' )
		created_at=$( date --date="$created_at" +%s )
		for pull_request in $pull_requests
		do
			RATE_LIMIT="$( waitForGH $RATE_LIMIT )"
			sha=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 2 2>/dev/null )
			RATE_LIMIT="$( waitForGH $RATE_LIMIT )"
			date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
			[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
				echo "$issue,$pull_request,$sha,$created_at,$date"
			}
		done
	done
	wait
done <<< "$BUG_LABELS"
