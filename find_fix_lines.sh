#!/usr/bin/env bash
export ROOT="$( pwd )"

#issue,$pull_request,$shaP,$created_at,$date,$diffSha,parent
ISSUE=$( echo "$1" | cut -d',' -f1 )
PULL_REQUEST=$( echo "$1" | cut -d',' -f2 )
COMMIT=$( echo "$1" | cut -d',' -f3 )
MIN_DATE=$( echo "$1" | cut -d',' -f4 )
MERGE_DATE=$( echo "$1" | cut -d',' -f5 )
COMMIT_DIFF=$( echo "$1" | cut -d',' -f6 )
COMMIT_TYPE=$( echo "$1" | cut -d',' -f7 )
ORIGINAL_INPUT="$1"

REPO="$2"
COMMIT_CACHE="$3"
SZZ_CACHE="$4"

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
	gh repo clone "$REPO" "$WORKING_DIR" >>"$ROOT/log" 2>>"$ROOT/log" || {
		echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
		exit 1
	}
	rm -rf "$WORKING_DIR/*"
}

cd "$WORKING_DIR"

COMMIT_LOOKUP="$( cat $COMMIT_CACHE | grep -e $COMMIT_DIFF -e $COMMIT | cut -d',' -f1 | head -n1 )"

[[ -z "$COMMIT_LOOKUP" ]] && {
	log "Commit $COMMIT / $COMMIT_DIFF ($COMMIT_TYPE) does not exist. Skipping SZZ step"
	echo "$ORIGINAL_INPUT,,,"
	exit 0
}
[[ "$COMMIT" != "$COMMIT_LOOKUP" ]] && {
	log "Mapping $COMMIT -> $COMMIT_LOOKUP via diff $COMMIT_DIFF"
	COMMIT="$COMMIT_LOOKUP"
}

log "Searching for bug-inducing commit candidates for fix $COMMIT (#$ISSUE)"

files=$( git diff --numstat "$COMMIT~1" "$COMMIT" | tr '\t' ' ' | cut -d' ' -f3 | grep -vE -e '\.spec' -e '\.test' -e '^tests?/' -e '/tests?/' -e 'bundle' | grep -E '\.(js|jsx|ts|tsx|java|c|cc|cpp|py|mjs|sh|bash|cs|html|css|php|swift|h|asm|lsp|dart|rb|go|gradle|groovy|kt|lua|rs)$' )
n=$( echo "$files" | wc -l )
log "Found $n files in fix commit"

CANDIDATES=$( mktemp )
HAS_PRINTED=$( mktemp )

SZZ_LINE(){
	line="$1"
	file="$2"
	DIFF="$3"
	COMMENT_TOKEN="$4"
	EXT="$5"

	pat1="$( echo $line | tr ':' ' ' | tr '[\+\-]' '.' )"
	pat2="@@.*@@"
	echo "$DIFF" | isDifferent "$pat1" "$pat2" "$COMMENT_TOKEN" || {
		log "Line $line matched when stripped, skipping."
		return
	}

	l1=$( echo "$line" | cut -d':' -f1 )
	l2=$( echo "$line" | cut -d':' -f2 )
	l1Stripped=$( echo "$l1" | tr -d '[+\-]' )
	to=$( echo "$l2" | tr -d '[+\-]' )
	n1=$( echo "$to" | cut -d',' -f1 )
	n2=$( echo "$to" | cut -d',' -f2 )
	offset=$(( $l1Stripped - $n1 ))
	[[ "$offset" -lt 0 ]] && offset=0
	n2=$(( $n2 + $offset ))
	n1=$(( $n1 - $offset ))

	[[ -z "$( echo $to | grep -o ',' )" ]] && {
		to="$to,$to"
	} || {
		[[ "$n2" -eq 0 ]] && {
			return
		}
		to="$n1,+$n2"
	}

	hash=$( echo "${COMMIT}${to}" | shasum | cut -d' ' -f1 )
	[[ -z "$( cat $SZZ_CACHE 2>/dev/null | grep -o $hash )" ]] || {
		log "[$COMMIT / $to] already exists in cache, skipping"
		return
	}
	echo "$hash" >> "$SZZ_CACHE"


	IGNORED_REV_FILE="$( mktemp )"
	IS_DONE=0
	while [[ "$IS_DONE" -eq 0 ]]
	do
		IS_DONE=1
		RAW=$( git blame -L "$to" "$COMMIT~1" --porcelain --ignore-revs-file "$IGNORED_REV_FILE" -- "$file" 2>>"$ROOT/log" )
		BLAME=$( echo "$RAW" | grep -v '^previous' | grep -oE '^[a-zA-Z0-9]{40}' | awk '!x[$0]++' )
		DATE=$( echo "$RAW" | grep -oE 'author-time [0-9]{10}' | cut -d' ' -f2 | awk '!x[$0]++' )
		log Checking $( echo "$BLAME" | wc -l ) possible blame commits
		i=1
		for blame in $BLAME
		do
			[[ -z "$( cat "$IGNORED_REV_FILE" 2>/dev/null | grep -o $blame )" ]] || {
				continue
			}
			[[ -z "$( cat "$CANDIDATES" 2>/dev/null | grep -o $blame )" ]] || {
				continue
			}

			date=$( echo "$DATE" | head -n"$i" | tail -n1  )

			[[ "$date" -gt "$MIN_DATE" ]] && {

				diffCount=$( git diff -U0 "$blame~1" "$blame" -- "$file" 2>/dev/null | wc -l )
				log "Commit $blame ($diffCount lines) was created after the issue report, iterating deeper ($date > $MIN_DATE)"

				[[ "$diffCount" -lt 2500 ]] && [[ "$diffCount" -gt 0 ]] && {
					echo "$blame" >> "$IGNORED_REV_FILE"
					awk -i inplace '!seen[$0]++' "$IGNORED_REV_FILE"
					IS_DONE=0
					continue
				}
				log "Line count for $blame was too high! ($diffCount), stopping recursion"
				continue
			}

			echo "$blame" >> "$CANDIDATES"
			[[ -z "$blame" ]] && {
				log "Blame was empty"
				continue
			}
			RAW=$( git diff "$blame~1" "$blame" 2>>"$ROOT/log" )
			[[ "$?" -ne 128 ]] && {
				diffSha=$( echo "$RAW" | grep -Ev -e '^diff --git' -e '^---' -e '^\+\+\+' -e '^index [0-9a-z]+\.\.[0-9a-z]+ [0-9a-z]+$' | shasum | cut -d' ' -f1 )
			} || {
				diff=$( date +"%T.%N" | shasum | cut -d' ' -f1 )
			}
			log "Found candidate commit $blame"
			echo "$ORIGINAL_INPUT,$blame,$diffSha,$file"
			echo 1 >> "$HAS_PRINTED"
			i=$(( $i + 1 ))
		done
	done
	# rm "$IGNORED_REV_FILE"
}

SZZ_FILE() {
	file="$1"
	EXT=$( echo $file | grep -Eo '\.[a-zA-Z]+$' )
	COMMENT_TOKEN="//"
	[[ -z "$( echo $EXT | grep -o '^\.(py|bash|sh|rb)$' )" ]] || COMMENT_TOKEN="#"

	DIFF=$( git diff -w -U0 "$COMMIT~1" "$COMMIT" -- "$file" 2>/dev/null | tail -n +5 )
	lines=$( echo "$DIFF" | grep -oE -e '@@.*@@' -e '^[-+].*' | grep -Eo '^@@.*@@' | grep -oE '[-0-9+,]+ [-0-9+,]+' | tr ' ' ':' )

	numLines=$( echo "$lines" | wc -l )
	log "Found $numLines lines of diff"
	[[ "$numLines" -gt 1000 ]] || [[ "$numLines" -eq 0 ]] && {
		log "Too many lines. Skipping file $file"
		return
	}

	lineIndex=0
	N=32
	for line in $lines
	do
		((i=i%N)); ((i++==0)) && wait

		log "Checking line $lineIndex/$numLines"
		lineIndex=$(( $lineIndex + 1 ))
		SZZ_LINE "$line" "$file" "$DIFF" "$COMMENT_TOKEN" "$EXT" &
	done
	wait
}

for file in $files
do
	SZZ_FILE "$file"
	wait
done
wait

rm "$CANDIDATES"

[[ -z "$( echo $HAS_PRINTED | grep -o 1 )" ]] && echo "$ORIGINAL_INPUT,,,"
rm "$HAS_PRINTED"

cd "$ROOT"
