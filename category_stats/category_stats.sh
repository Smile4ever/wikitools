#!/bin/bash
# Save the data of a category at certain intervals for analysis / statistics
#
# Files per run:
# * List of current pages in category
# * Count of current pages in category
# * Differences in page titles compared to the last run
# * Count of differences in page titles

# Change this or use command line parameters
if [[ $CATEGORY == "" ]]; then
	CATEGORY="Categorie:Wikipedia:Onbereikbare externe link"
fi
if [[ $PROTOCOL == "" ]]; then
	PROTOCOL="https://"
fi
if [[ $WIKI == "" ]]; then
	WIKI="nl.wikipedia.org"
fi
if [[ $DATADIRECTORY == "" ]]; then
	DATADIRECTORY="run"
fi

#You can also specify a category on the command line using --cat or -c
#For example, category_stats.sh --cat Category:Wikipedia
if [[ "$1" = "--cat" || "$1" = "-c" ]]
then
	CATEGORY=$2
fi

SLEEPDURATION=3600 #each hour

while true; do
	SNAPSHOT=`date +"%Y%m%d%H%M%S"`
	mkdir "$DATADIRECTORY/$SNAPSHOT"

	echo "Making snapshot $SNAPSHOT for $CATEGORY.."
	CMFROM=""
	LENGTH=500
	start=`date +%s`

	mv list.txt prev.txt 2>/dev/null
	touch prev.txt
	PREV=`cat prev.txt`

	while [[ $LENGTH -eq 500 ]]
	do	
		rm api.php* 2>/dev/null

		URL="$PROTOCOL$WIKI/w/api.php?action=query&list=categorymembers&cmtitle=$CATEGORY&format=json&cmlimit=500&cmcontinue=$CMFROM"
		wget --user-agent="category_stats tool by Smile4ever" "$URL" 2&>/dev/null
		CMFROM=`jq -r '.continue.cmcontinue' api.php*` #cmcontinue

		size=$(stat -c%s api.php*)
		empty=$(stat -c%s empty.json)

		if [[ "$size" -gt "$empty" ]]; then
			# Make list
			jq -r '.query.categorymembers[] | .title' api.php* >> list.txt
			WC=`wc -l list.txt | grep -o "[0-9]\+"`
			echo "($WC) $CMFROM"
			LENGTH=`jq -r '.query.categorymembers | length' api.php*`
		else
			echo "INFO: No results"
			LENGTH=0
		fi
	done

	# Copy list
	cp list.txt "$DATADIRECTORY/$SNAPSHOT/list.txt"

	# Make diff
	grep -v -f prev.txt list.txt > diff.txt

	# Copy list
	cp diff.txt "$DATADIRECTORY/$SNAPSHOT/diff.txt"

	# Copy line count
	LISTCOUNT=`wc -l list.txt | grep -o "[0-9]\+"`
	echo $LISTCOUNT > "$DATADIRECTORY/$SNAPSHOT/list-count.txt"
	DIFFCOUNT=`wc -l diff.txt | grep -o "[0-9]\+"`
	echo $DIFFCOUNT > "$DATADIRECTORY/$SNAPSHOT/diff-count.txt"

	# End run
	end=`date +%s`
	RUNTIME=$((end-start))

	# Display results
	echo ""
	echo "Your data is stored in $DATADIRECTORY/$SNAPSHOT"
	echo ""
	echo "Total items : $LISTCOUNT"
	echo "New items   : $DIFFCOUNT"
	echo "Run time    : $RUNTIME"
	echo ""
	echo "Next run in $SLEEPDURATION seconds"

	#sizediff=$(stat -c%s diff.txt)
	#result=`cat diff.txt`

	#if [[ "$sizediff" -gt 1 ]]; then
	#	if [ "$PREV" != "$result" ]; then
	#		wc -l diff.txt | grep -o "[0-9]\+"
	#			while read article
	#		do
	#			echo "New article: $article"
	#		done < diff.txt
	#	else
	#		echo "No differences compared to last time"
	#	fi
	#else
	#	echo "Difference with last time is zero"
	#fi

	rm diff.txt
	rm api.php*
	
	sleep $SLEEPDURATION
done
