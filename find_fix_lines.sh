#!/usr/bin/env bash
export ROOT="$( pwd )"
COMMIT=$( echo "$1" | cut -d',' -f1 )
ISSUE=$( echo "$1" | cut -d',' -f2 )
MIN_DATE=$( echo "$1" | cut -d',' -f3 )
REPO="$2"
export hash=$( echo "$REPO" | shasum | cut -d' ' -f1)
export WORKING_DIR="$ROOT/$hash"

log() {
	# echo "$@" #>/dev/null
	$ROOT/log.sh "$ROOT" "$@"
}

isDifferent(){
	pat1="$1"
	pat2="$2"
	COMMENT_TOKEN="$3"
	USE_LINES="$4"
	INPUT=$(cat)
	CHANGED=$( echo "$INPUT" | awk "f;/$pat1/{f=1}" | sed "/$pat2/q" )

	ADDITIONS=$( echo "$CHANGED" | grep '^+' | cut -c2- | tr -d '[ \t]' | grep -Ev "^$COMMENT_TOKEN" | tr -d '[\r\n]' )
	DELETIONS=$( echo "$CHANGED" | grep '^-' | cut -c2- | tr -d '[ \t]' | grep -Ev "^$COMMENT_TOKEN" | tr -d '[\r\n]' )
	[[ "$COMMENT_TOKEN" = "//" ]] && {
		ADDITIONS=$( echo "$ADDITIONS" | perl -pe 's|/\*((?!\*/).)*\*/||g' )
		DELETIONS=$( echo "$DELETIONS" | perl -pe 's|/\*((?!\*/).)*\*/||g' )
	}

	[[ "$ADDITIONS" = "$DELETIONS" ]] && {
		return 1
	}
	return 0
}


[ -d "$WORKING_DIR" ] || {
	gh repo clone "$REPO" "$WORKING_DIR" >>log 2>>log || {
		echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
		exit 1
	}
	rm -rf "$WORKING_DIR/*"
}

cd "$WORKING_DIR"


log "Searching for bug-inducing commit candidates for fix $COMMIT (#$ISSUE)"

files=$( git diff --numstat "$COMMIT~" "$COMMIT" | tr '\t' ' ' | cut -d' ' -f3 | grep -vE -e '\.spec' -e '^test/' -e '/test/' | grep -E '\.(js|jsx|ts|tsx|java|c|cc|cpp|py|mjs|sh|bash|cs|html|css|php|swift|h|asm|lsp|dart|rb|go|gradle|groovy|kt|lua|rs)$' )
n=$( echo $files | wc -l )
log "Found $n files in fix commit"

CANDIDATES=$( mktemp )

for file in $files
do
	EXT=$( echo $file | grep -Eo '\.[a-zA-Z]+$' )
	COMMENT_TOKEN="//"
	[[ -z "$( echo $EXT | grep -o '^\.(py|bash|sh|rb)$' )" ]] || COMMENT_TOKEN="#"

	DIFF=$( git diff -w -U0 "$COMMIT~1" "$COMMIT" -- "$file" | tail -n +5 )
	lines=$( echo "$DIFF" | grep -oE -e '@@.*@@' -e '^[-+].*' | grep -Eo '^@@.*@@' | grep -oE '[-0-9+,]+ [-0-9+,]+' | tr ' ' ':' )

	for line in $lines
	do
		pat1="$( echo $line | tr ':' ' ' | tr '[\+\-]' '.' )"
		pat2="@@.*@@"
		echo "$DIFF" | isDifferent "$pat1" "$pat2" "$COMMENT_TOKEN" || {
			log "Line $line matched when stripped, skipping."
			continue
		}

		l1=$( echo "$line" | cut -d':' -f1 )
		l2=$( echo "$line" | cut -d':' -f2 )
		to=$( echo "$l2" | tr -d '[+\-]' )
		[[ -z "$( echo $to | grep -o ',' )" ]] && {
			to="$to,$to"
		} || {
			n1=$( echo "$to" | cut -d',' -f1 )
			n2=$( echo "$to" | cut -d',' -f2 )
			[[ "$n2" -eq 0 ]] && {
				continue
			}
			to="$n1,+$n2"
		}

		IGNORED_REV_FILE="$( mktemp )"
		IS_DONE=0
		while [[ "$IS_DONE" -eq 0 ]]
		do
			IS_DONE=1
			# echo git blame -L "$to" "$COMMIT~1" --porcelain --ignore-revs-file "$IGNORED_REV_FILE" -- "$file" 2>>"$ROOT/log"
			RAW=$( git blame -L "$to" "$COMMIT~1" --porcelain --ignore-revs-file "$IGNORED_REV_FILE" -- "$file" 2>>"$ROOT/log" )
			BLAME=$( echo "$RAW" | grep -v '^previous' | grep -oE '[a-zA-Z0-9]{40}' | awk '!x[$0]++' )
			DATE=$( echo "$RAW" | grep -oE 'author-time [0-9]{10}' | cut -d' ' -f2 | awk '!x[$0]++' )

			log Checking $( echo "$BLAME" | wc -l ) possible blame commits
			i=1
			for blame in $BLAME
			do
				[[ -z "$( cat "$IGNORED_REV_FILE" | grep -o $blame )" ]] || {
					continue
				}
				[[ -z "$( cat "$CANDIDATES" | grep -o $blame )" ]] || {
					continue
				}

				date=$( echo "$DATE" | head -n"$i" | tail -n1  )

				[[ "$date" -gt "$MIN_DATE" ]] && {
					log "Commit $blame was created after the issue report, iterating deeper ($date > $MIN_DATE)"
					echo "$blame" >> "$IGNORED_REV_FILE"
					awk -i inplace '!seen[$0]++' "$IGNORED_REV_FILE"
					IS_DONE=0
					continue
				}

# 				PATTERN=$( echo "$RAW" | tail -n1  | tr '\t' ' ' | grep -Eo -e '[^$^ ]+' | head -n1 )
# 				while read -r diff_line; do
# 					[[ -z "$( echo $diff_line | grep -o '^@@ ' )" ]] || {
# 						echo "Checking $PATTERN"
# 						[[ -z "$( echo $ROLLING_DIFF | grep -o "$PATTERN" )" ]] || {
# 							echo "-------------"
# 							echo "$PATTERN"
# 							echo "FOUND MATCH!!!"
# 							echo "$CONTEXT"
# 							echo "$ROLLING_DIFF"
# 							echo "-------------"
# 						}
# 						ROLLING_DIFF=""
# 						CONTEXT="$diff_line"
# 						continue
# 					}
# 					ROLLING_DIFF="${ROLLING_DIFF}
# ${diff_line}"
# 				done <<< "$( git diff -U0 -w $blame~1 $blame )"
# 				echo git diff -U0 -w $blame~1 $blame

				#TODO: Check for empty diff
				echo "$blame" >> "$CANDIDATES"
				diffSha=$( git diff $blame~ $blame | grep -Ev -e '^diff --git' -e '^---' -e '^\+\+\+' -e '^index [0-9a-z]+\.\.[0-9a-z]+ [0-9a-z]+$' | shasum | cut -d' ' -f1 )
				log "Found candidate commit $blame"
				echo "$COMMIT,$blame,$diffSha,$ISSUE,$file"
				i=$(( $i + 1 ))
			done
		done
		rm "$IGNORED_REV_FILE"
	done
done
rm "$CANDIDATES"
cd "$ROOT"
