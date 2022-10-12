#!/usr/bin/env bash
ROOT="$(pwd)"
REPO="$1"
BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | cut -d$'\t' -f1 | grep -i bug )

while IFS="\n" read -r label; do
	ISSUES=$( gh issue list --repo "$REPO" -l "$label" -L 1000 --search "is:closed" | cut -d$'\t' -f1 )
	for issue in $ISSUES
	do
		pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" | grep -Eo 'pull/[0-9]{1,4}' | sort | uniq | cut -d '/' -f2 )
		created_at=$( gh api "/repos/$REPO/issues/$issue" | grep -Eo 'created_at[^,]*,' | head -n1 | cut -d':' -f2- | tr -d '"' | tr -d ',' )
		created_at=$( date --date="$created_at" +%s )
		for pull_request in $pull_requests
		do
			sha=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 2 2>/dev/null )
			date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
			[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
				echo "$issue,$pull_request,$sha,$created_at,$date"
			}
		done
	done
	wait
done <<< "$BUG_LABELS"
