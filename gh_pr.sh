#!/usr/bin/env bash
export ROOT="$(pwd)"
REPO="$1"
CUSTOM_LABELS="$2"

log() {
	$ROOT/log.sh "$ROOT" "$@"
}

RATE_LIMIT=$( $ROOT/rate_limit.sh "$ROOT" )

BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | cut -d$'\t' -f1 | grep -iE -e "bug" -e "^confirm" -e "[^n]confirm" -e "important" -e "critical" -e "(high|top).*priority" -e "has.*(pr|pull)" -e "merge" -e "major" -e '(p|priority) ?([0-9]*|high|medium|low|mid)')

[[ -z "$CUSTOM_LABELS" ]] || {
	CUSTOM_LABELS=$( echo "$CUSTOM_LABELS" | xargs -n1 )
	BUG_LABELS+=$'\n'$(printf '%s' "$CUSTOM_LABELS")
}

log "Using labels $( echo $BUG_LABELS | xargs )"

while IFS="\n" read -r label; do
	log "Querying for issues with label: $label"
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	ISSUES=$( gh issue list --repo "$REPO" -l "$label" -L 1000 --search "is:closed" | cut -d$'\t' -f1 )
	log Found $( echo "$ISSUES" | wc -l ) issues
	for issue in $ISSUES
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" 2>>"$ROOT/log" | grep -Eo '[^/]+/[^/]+/pull/[0-9]+' | grep "$REPO" | sort | uniq | cut -d '/' -f4 )
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		created_at=$( gh api "/repos/$REPO/issues/$issue" 2>>"$ROOT/log" | grep -Eo 'created_at[^,]*,' | head -n1 | cut -d':' -f2- | tr -d '"' | tr -d ',' )

		[[ -z "$created_at" ]] && {
			log "created_at for issue=$issue returned empty"
			continue
		}
		[[ -z "$pull_requests" ]] && {
			log "pull_requests for issue=$issue returned empty"
			continue
		}

		created_at=$( date --date="$created_at" +%s )

		log "Issue $issue, created at $created_at. Pull requests: $( echo $pull_requests | xargs )"

		for pull_request in $pull_requests
		do
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			sha=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 2 2>/dev/null )
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
			log "$pull_request, Commit SHA: $sha, date: $date"

			[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
				echo "$issue,$pull_request,$sha,$created_at,$date"
			}
		done
	done
	wait
done <<< "$BUG_LABELS"
