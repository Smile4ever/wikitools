#!/bin/bash
# Watch a category
#
# Features:
# * Only open the category page when there are new items (that differ from the last time)
#

# Change this or use command line parameters
#CATEGORY="Categorie:Wikipedia:Onbereikbare externe link"
CATEGORY="Categorie:Wikipedia:Nuweg"
PROTOCOL="https://"
WIKI="nl.wikipedia.org"

#You can also specify a category on the command line using --cat or -c
#For example, watch_category.sh --cat Category:Wikipedia
if [[ "$1" = "--cat" || "$1" = "-c" ]]
then
	CATEGORY=$2
fi

echo "Getting the category listing for category $CATEGORY.."
rm api.php*
PREV=`cat result.txt`
wget "$PROTOCOL$WIKI/w/api.php?action=query&list=categorymembers&cmtitle=$CATEGORY&format=json&cmlimit=500" 2&>/dev/null

size=$(stat -c%s api.php*)
empty=$(stat -c%s empty.json)

if [[ "$size" -gt "$empty" ]]; then
    jq -r '.query.categorymembers[] | .title' api.php* > result.txt
    result=`cat result.txt`
    if [ "$PREV" != "$result" ]; then
		 #Some notification daemons do not support links, like MATE
		#ahref='<a href="$PROTOCOL$WIKI/wiki/$CATEGORY"></a>'
		#notify-send "$CATEGORY" "$ahref\nNew items:\n$result"
		notify-send "$CATEGORY" "New items:\n$result"
		#Auto-open the category page when there are new items
		xdg-open "$PROTOCOL$WIKI/wiki/$CATEGORY"
	else
		echo "Not different from the last time"
	fi
else
	echo "No results"
	#notify-send "No results" "http://nl.wikipedia.org/wiki/Categorie:Wikipedia:Nuweg"
fi
