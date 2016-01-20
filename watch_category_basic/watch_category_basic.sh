#!/bin/bash
# Watch a category
#
# Features:
# * Open pages or category page
# * Only open new items (items that differ from the last time)

# Change this or use command line parameters
#CATEGORY="Categorie:Wikipedia:Onbereikbare externe link"
if [[ $CATEGORY == "" ]]; then
	CATEGORY="Categorie:Wikipedia:Nuweg"
fi
if [[ $PROTOCOL == "" ]]; then
	PROTOCOL="https://"
fi
if [[ $WIKI == "" ]]; then
	WIKI="nl.wikipedia.org"
fi
if [[ $OPENPAGES == "" ]]; then
	OPENPAGES="true"
fi

MESSAGE=""

#You can also specify a category on the command line using --cat or -c
#For example, watch_category.sh --cat Category:Wikipedia
if [[ "$1" = "--cat" || "$1" = "-c" ]]
then
	CATEGORY=$2
fi

echo "Getting the category listing for category $CATEGORY.."
date +"%T"
	
rm api.php* 2>/dev/null
mv result.txt prev.txt 2>/dev/null
PREV=`cat prev.txt`
wget --user-agent="watch_category tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=categorymembers&cmtitle=$CATEGORY&format=json&cmlimit=500" 2&>/dev/null

size=$(stat -c%s api.php*)
empty=$(stat -c%s empty.json)

if [[ "$size" -gt "$empty" ]]; then
	jq -r '.query.categorymembers[] | .title' api.php* > result.txt
	grep -v -f prev.txt result.txt > diff.txt
	result=`cat diff.txt`
else
	echo "No results"
	if [[ $INFOMESSAGES == "true" ]]; then
		echo "No results" > ~/irc/irc.freenode.net/$CHANNEL/in
	fi
	exit 0
fi

sizediff=$(stat -c%s diff.txt)

if [[ "$sizediff" -gt 1 ]]; then
	if [ "$PREV" != "$result" ]; then
		notify-send "$CATEGORY" "New items:\n$result"
		#Auto-open the category page when there are new items
			
		if [ "$OPENPAGES" == "true" ]; then
			while read article
			do
				xdg-open "$PROTOCOL$WIKI/wiki/$article"
			done < diff.txt
		else
			xdg-open "$PROTOCOL$WIKI/wiki/$CATEGORY"
		fi
				
		while read article
		do
			echo "Er is een nieuw artikel in $PROTOCOL$WIKI/wiki/$CATEGORY"
			echo "$PROTOCOL$WIKI/wiki/$article"
		done < diff.txt
	else
		echo "Not different from the last time"
	fi
else
	echo "Difference with last time is zero."
fi

rm diff.txt
