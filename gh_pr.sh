#!/usr/bin/env bash
ROOT="$(pwd)"

REPO="$1"
DEPLOYMENT="$2"

export hash=$( echo "$REPO" | shasum | cut -d' ' -f1)
export WORKING_DIR="$(pwd)/$hash"

[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"

[[ "$DEPLOYMENT" -eq 1 ]] && {
	tmpOutput="$(mktemp)"
	gh repo clone "$REPO" "$WORKING_DIR" >"$tmpOutput" 2>"$tmpOutput" || {
		echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
		cat "$tmpOutput" >&2
		rm "$tmpOutput"
		exit 1
	}
	rm "$tmpOutput"
	cd "$WORKING_DIR"
}


[[ "$DEPLOYMENT" -eq 0 ]] && {
	export deployments=$( gh release list --repo "$REPO" -L 1000 | cut -f3 | tac )
}
[[ "$DEPLOYMENT" -eq 1 ]] && {
	export deployments=$( git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's/^refs\/tags\///g' )
}

convert_to_deployment() {
	version="$1"
	[[ -z "$( echo $version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' )" ]] && {
		gh pr view --repo "$REPO"
	}
	deployment=$( echo "$deployments" | grep -oE "v?$version" )
	echo "$deployment"
	return
}

BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | grep -i bug | cut -d'	' -f1 )

for label in $BUG_LABELS
do
	ISSUES=$( gh issue list --repo "$REPO" -l "$label" -L 1000 --search "is:closed" | cut -d'	' -f1 )

	N=1
	for issue in $ISSUES
	do
		((i=i%N)); ((i++==0)) && wait
		pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" | grep -Eo 'pull/[0-9]{1,4}' | sort | uniq | cut -d '/' -f2 )
		for pull_request in $pull_requests
		do
			sha=$( gh api "/repos/$REPO/pulls/$pull_request/commits" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 1 2>/dev/null )
			date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>/dev/null | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
			[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && {
				echo "$issue,$pull_request,$sha,$date"
			}
		done
	done
	wait
done

[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
