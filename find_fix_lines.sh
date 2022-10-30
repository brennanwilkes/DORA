#!/usr/bin/env bash
ROOT="$1"
COMMIT=$( echo "$2" | cut -d',' -f1 )
ISSUE=$( echo "$2" | cut -d',' -f2 )
MAX_DATE=$( echo "$2" | cut -d',' -f3 )

log() {
	echo "$@" >/dev/null
	#$ROOT/log.sh "$ROOT" "$@"
}

log "Searching for bug-inducing commit candidates for fix $COMMIT (#$ISSUE)"

files=$( git diff --numstat "$COMMIT~" "$COMMIT" | tr '\t' ' ' | cut -d' ' -f3 | grep -vE -e '\.spec' -e '^test/' -e '/test/' | grep -E '\.(js|jsx|ts|tsx|java|yaml|yml|c|cc|cpp|py|mjs|sh|bash|cs|html|css|php|swift|h|asm|lsp|dart|rb|go|gradle|groovy|kt|lua|rs)$' )
n=$( echo $files | wc -l )
log "Found $n files in fix commit"

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
		CHANGED=$( echo "$DIFF" | awk "f;/$pat1/{f=1}" | sed "/$pat2/q" )
		ADDITIONS=$( echo "$CHANGED" | grep '^+' | cut -c2- | tr -d '[ \t]' | grep -Ev "^$COMMENT_TOKEN" | tr -d '[\r\n]' )
		DELETIONS=$( echo "$CHANGED" | grep '^-' | cut -c2- | tr -d '[ \t]' | grep -Ev "^$COMMENT_TOKEN" | tr -d '[\r\n]' )
		[[ "$COMMENT_TOKEN" = "//" ]] && {
			ADDITIONS=$( echo "$ADDITIONS" | perl -pe 's|/\*((?!\*/).)*\*/||g' )
			DELETIONS=$( echo "$DELETIONS" | perl -pe 's|/\*((?!\*/).)*\*/||g' )
		}

		[[ "$ADDITIONS" = "$DELETIONS" ]] && {
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
		RAW=$( git blame -L "$to" "$COMMIT~1" --porcelain  -- "$file" 2>>"$ROOT/log" )
		[[ "$?" -ne 0 ]] && {
			log "Git blame exited failure, skipping"
			continue
		}
		BLAME=$( echo "$RAW" | grep -oE '[a-zA-Z0-9]{40}' | head -n1 )
		DATE=$( echo "$RAW" | grep -oE 'author-time [0-9]{10}' | head -n1 | cut -d' ' -f2 )
		LINE_START=$( echo "$RAW" | head -n1 | cut -d' ' -f2 )
		NUM_LINES=$( echo "$RAW" | head -n1 | cut -d' ' -f4 )

		[[ "$DATE" -lt "$MAX_DATE" ]] && {
			log "Commit $BLAME was created prior to issue report, skipping"
			continue
		}

		git diff -w -U0 "$BLAME~1" "$BLAME" -- "$file" | awk "f;/^@@ -$LINE_START/{f=1}" | sed "/$pat2/q" | grep -v '^@@'

		# echo "-------------------------------------"
		# echo "$CHANGED" | grep -v '^@@'
		# echo "-----------"
		# echo "$line"
		# echo "-----------"
		# git blame -L "$to" "$COMMIT~1"  -- "$file"
		# echo "-----------"
		# git blame -L "$to" "$COMMIT~1" --line-porcelain -- "$file"
		# echo "-----------"
		# git diff -w -U0 "$BLAME~1" "$BLAME" -- "$file"
		# echo "-------------------------------------"

		log "Found candidate commit $BLAME"
		echo "$COMMIT,$BLAME,$ISSUE,$file"
		exit
	done

done
# echo "---------------------------------------------------------------------------"
