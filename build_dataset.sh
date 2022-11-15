#!/usr/bin/env bash

processRepo(){
	REPO="$1"
	DATA=$( gh api "/repos/$REPO/git/refs/tags" 2>/dev/null )
	[[ "$?" != 0 ]] && return
	RELEASES=$( echo "$DATA" | grep -Eo '.ref.: ?.refs/tags/v?[0-9]+\.[0-9]+\.?[0-9]*[^"]*",' | sort | uniq | wc -l )
	[[ "$RELEASES" -gt 50 ]] && {
		BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" )
		[[ "$?" != 0 ]] && echo "Bad repo for labels: $REPO" >&2
		BUG_LABELS=$( echo "$BUG_LABELS" | cut -d$'\t' -f1 | grep -iE -e "^bug" -e '[ :/-]bug' -e "^confirm" -e "[^n]confirm" -e "important" -e "critical" -e "(high|top).*priority" -e "has.*(pr|pull)" -e '^(p|priority) ?([0-9]+|high|medium|low|mid)')
		BUG_LABELS=$( echo "$BUG_LABELS" | grep -vE -e 'stalled' -e 'won.?t.*fix' -e 'blocked' -e 'invalid' -e 'feature' -e '^docs?$' -e '^documentation$' -e 'do.not.*merge' )
		NUM_LABELS=$( echo "$BUG_LABELS" | wc -l )

		[[ "$NUM_LABELS" -ge 1 ]] && {
			BUG_LABELS=$( echo "$BUG_LABELS" | xargs -n1 -I {} echo '"{}"' | paste -sd "," - )

			[[ "$( gh api -H 'Accept: application/vnd.github+json' '/rate_limit' | grep -o 'search....limit..[0-9]*,.used..[0-9]*..remaining..[0-9]*' | grep -o '[0-9]*$' )" -lt 10 ]] && sleep 60

			DATA=$( gh api -X GET search/issues -f per_page=1 -f "page=1" -f q="repo:$REPO is:closed label:$BUG_LABELS" )
			[[ "$?" != 0 ]] && echo "Bad repo for issues: $REPO" >&2
			NUM_ISSUES=$( echo "$DATA" | grep -oE "total_count..[0-9]+" | grep -Eo '[0-9]+' | head -n1 )


			[[ "$NUM_ISSUES" -gt 100 ]] && {
				TOTAL_COMMITS=$( gh api -i "/repos/$REPO/commits?per_page=1" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p' )

				FIRST_COMMIT=$( gh api "/repos/$REPO/commits?per_page=1&page=$TOTAL_COMMITS" | node parse_pr_commit_json.js 11 )
				LAST_COMMIT=$( gh api "/repos/$REPO/commits?per_page=1&page=1" | node parse_pr_commit_json.js 11 )

				echo "$REPO,$RELEASES,$NUM_ISSUES,$TOTAL_COMMITS,$FIRST_COMMIT,$LAST_COMMIT"
			}

			sleep 2
		}
	}

}

N=16
while read REPO
do
	((i=i%N)); ((i++==0)) && wait
	processRepo "$REPO" &
done < "${1:-/dev/stdin}"
