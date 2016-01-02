#!/bin/bash
# Watch a category
#
# Features:
# * Open pages or category page
# * Only open new items (items that differ from the last time)
# * IRC bot

# Notes
# 
# To quit, use ./quitbot.sh 

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

#IRC
if [[ $BOTNAME == "" ]]; then
	BOTNAME="smilebot-watchcat"
fi
if [[ $NETWORK == "" ]]; then
	NETWORK="irc.freenode.net"
fi
if [[ $CHANNEL == "" ]]; then
	CHANNEL="#wikipedia-nl-vandalism"
fi
if [[ $INFOMESSAGES == "" ]]; then
	INFOMESSAGES="false"
fi
if [[ $SPEAKLANG == "" ]]; then
	SPEAKLANG="en"
fi
MESSAGE=""

#You can also specify a category on the command line using --cat or -c
#For example, watch_category.sh --cat Category:Wikipedia
if [[ "$1" = "--cat" || "$1" = "-c" ]]
then
	CATEGORY=$2
fi

# --init cannot be passed in a loop!
if [[ "$1" == "--init" ]]
then
	#MESSAGE="I have been initialized"
    ./init.sh 2>/dev/null
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd
echo "Starting $BOTNAME, joining $CHANNEL"
#rm -rf irc
ii -s irc.freenode.net -n $BOTNAME -f "$BOTNAME running on watch_category.sh" &
sleep 15
echo "/j $CHANNEL"> ~/irc/irc.freenode.net/in
#sleep 5
cd $DIR

echo "Getting the category listing for category $CATEGORY.."

while true; do
	date +"%T"
	
	#~ song/./wmctrl.sh
	
	#~ while read song
	#~ do
		#~ echo "Song: $song" > ~/irc/irc.freenode.net/$CHANNEL/in
		#~ ARTISTSONG=`echo $song | sed 's/\(.*\)-.*/\1/'`
		#~ wget -O song/lyrics.txt "http://hugsmile.eu/lyricscore/api/v1/?filename=$ARTISTSONG&format=text"
		#~ lyrics=`cat song/lyrics.txt`
		#~ echo "Lyrics for $ARTISTSONG:" > ~/irc/irc.freenode.net/$CHANNEL/in
		#~ while read lyricsline
		#~ do
			#~ echo "$lyricsline" > ~/irc/irc.freenode.net/$CHANNEL/in
			#~ sleep 0.4
		#~ done < song/lyrics.txt
		#~ sleep 2
	#~ done < song/list.txt
	
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
			 #Some notification daemons do not support links, like MATE
			#ahref='<a href="$PROTOCOL$WIKI/wiki/$CATEGORY"></a>'
			#notify-send "$CATEGORY" "$ahref\nNew items:\n$result"
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
				#echo "reading.."
				#pwd
				#cat "/home/geoffrey/irc/irc.freenode.net/$CHANNEL/out"
				message="There is a new article in"
				if [[ $SPEAKLANG == "nl" ]]; then
					message="Er is een nieuw artikel in"
				fi
				echo "$message $PROTOCOL$WIKI/wiki/$CATEGORY" > ~/irc/irc.freenode.net/$CHANNEL/in
				
				article_underscore=`echo $article | sed -e 's/ /_/g'`
				
				echo "$PROTOCOL$WIKI/wiki/$article_underscore" > ~/irc/irc.freenode.net/$CHANNEL/in
			done < diff.txt
		else
			echo "Not different from the last time"
			if [[ $INFOMESSAGES == "true" ]]; then
				echo "Not different from the last time" > ~/irc/irc.freenode.net/$CHANNEL/in
			fi
		fi
	else
		echo "Difference with last time is zero."
		if [[ $INFOMESSAGES == "true" ]]; then
			echo "Difference with last time is zero." > ~/irc/irc.freenode.net/$CHANNEL/in
		fi
	fi

	rm diff.txt
	sleep 20
done
