#!/usr/bin/env bash

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
		gh issue view --repo "$REPO" "$issue" -c | grep -Eoi '(fixed|closed|closes|resolved|included).*(in|with|by|under|after).*(#[0-9]{0,4}|v?[0-9]+.[0-9]+.[0-9]+[a-zA-Z_0-9-]*)' | grep -Eo -e '(#[0-9]{1,4}|[0-9]+\.[0-9]+\.[0-9]+)' | tr -d "'" | xargs -n1 -I {} echo "$issue {}" 2>/dev/null &
	done
	wait
done

[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
