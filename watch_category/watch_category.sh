#!/bin/bash
# watch_category 1.0
# Watch a category on a MediaWiki website
#
# Features:
# * Open pages or category page
# * Only open/show new items (items that differ from the last time)
# * IRC bot

# Change this or use command line parameters
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
	OPENPAGES="false"
fi
if [[ $SECONDS == "" ]]; then
	SECONDS=60
fi
if [[ $SPEAKLANG == "" ]]; then
	SPEAKLANG="en"
	#SPEAKLANG="nl"
fi

#IRC
if [[ $BOTNAME == "" ]]; then
	BOTNAME="smilebot-watch"
fi
if [[ $NETWORK == "" ]]; then
	NETWORK="irc.freenode.net"
fi
if [[ $CHANNEL == "" ]]; then
	CHANNEL="#wikipedia-nl-vandalism"
	#CHANNEL="#cvn-wp-nl"
	#CHANNEL=#hugsmile
fi
if [[ $INFOMESSAGES == "" ]]; then
	INFOMESSAGES="false"
fi
if [[ $IRCENABLED == "" ]]; then
	IRCENABLED="true"
fi
if [[ $DESKTOPINT == "" ]]; then
	DESKTOPINT="false"
fi
if [[ $USERNAME == "" ]]; then
	#USERNAME="smile"
fi

function msg {
	if [[ $USERNAME == "" ]]; then
		echo "$1" > ~/irc/irc.freenode.net/$CHANNEL/in
	else
		echo "/PRIVMSG $USERNAME :$1"> ~/irc/irc.freenode.net/$CHANNEL/in
	fi
}

MESSAGE=""

#You can also specify a category on the command line using --cat or -c
#For example, watch_category.sh --cat Category:Wikipedia
if [[ "$1" = "--cat" || "$1" = "-c" ]]
then
	CATEGORY=$2
fi

# --init cannot be passed in a loop!
if [[ "$1" == "--init" || "$1" == "-i" ]]
then
    ./init.sh
fi

if [[ "$1" == "--forcerestart" || $1 == "-f" ]]
then
	if [[ $IRCENABLED == "true" ]]; then
		./quitbot.sh "$SPEAKLANG"
		sleep 5 #wait for the bot to quit
	fi
fi

if [[ "$1" == "--quit" || "$1" == "-q" ]]
then
	if [[ $IRCENABLED == "true" ]]; then
		./quitbot.sh "$SPEAKLANG"
		exit
	fi
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ $IRCENABLED == "true" ]]; then
	cd
	
	if [[ $SPEAKLANG == "nl" ]]; then
		echo "Starten van $BOTNAME, verbinden met $CHANNEL op $NETWORK"
		echo "Desktopintegratie is $DESKTOPINT, IRC ingeschakeld is $IRCENABLED"
	else
		echo "Starting $BOTNAME, joining $CHANNEL on $NETWORK"
		echo "Desktop integration is $DESKTOPINT, IRC enabled is $IRCENABLED"
	fi
	
	MESSAGE="$BOTNAME running on watch_category.sh"
	if [[ $SPEAKLANG == "nl" ]]; then
		MESSAGE="$BOTNAME draait op watch_category.sh"
	fi
	
	ii -s irc.freenode.net -n $BOTNAME -f "${MESSAGE}" &
	sleep 15
	echo "/j $CHANNEL"> ~/irc/irc.freenode.net/in
	#msg "/PRIVMSG $USERNAME: Starting $BOTNAME, joining $CHANNEL on $NETWORK"
	MESSAGE="I now watch ${PROTOCOL}${WIKI}/wiki/${CATEGORY} for new items."
	if [[ $SPEAKLANG == "nl" ]]; then
		MESSAGE="Ik hou nu ${PROTOCOL}${WIKI}/wiki/${CATEGORY} in de gaten voor nieuwe items."
	fi
	msg "$MESSAGE"
	cd $DIR
fi

MESSAGE="Getting the category listing for category $CATEGORY.."
if [[ $SPEAKLANG == "nl" ]]; then
	MESSAGE="De inhoud van de categorie $CATEGORY ophalen.."
fi
echo $MESSAGE

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
		MESSAGE="No results"
		if [[ $SPEAKLANG == "nl" ]]; then
			MESSAGE="Geen resultaten"
		fi
		echo $MESSAGE
		
		if [[ $INFOMESSAGES == "true" ]]; then
			msg $MESSAGE
		fi
		sleep $SECONDS
		continue
	fi
	NUMBEROFPAGES=$(wc -l < diff.txt)
	sizediff=$(stat -c%s diff.txt)

	if [[ "$sizediff" -gt 1 ]]; then
		if [ "$PREV" != "$result" ]; then
			 #Some notification daemons do not support links, like MATE
			#ahref='<a href="$PROTOCOL$WIKI/wiki/$CATEGORY"></a>'
			#notify-send "$CATEGORY" "$ahref\nNew items:\n$result"
			
			#Auto-open the category page when there are new items
							
			if [[ $DESKTOPINT == "true" ]]; then
				MESSAGE = "$CATEGORY" "New items:\n$result"
				if [[ $SPEAKLANG == "nl" ]]; then
					MESSAGE="$CATEGORY" "Nieuwe items:\n$result"
				fi
			
				notify-send $MESSAGE
				
				if [[ "$OPENPAGES" == "true" ]] && [[ $NUMBEROFPAGES -lt 3 ]]; then
					while read article
					do
						xdg-open "$PROTOCOL$WIKI/wiki/$article"
					done < diff.txt
				else
					xdg-open "$PROTOCOL$WIKI/wiki/$CATEGORY"
				fi
			fi
			
			if [[ $IRCENABLED == "true" ]]; then
				MESSAGE = "Number of lines: $NUMBEROFPAGES"
				if [[ $SPEAKLANG == "nl" ]]; then
					MESSAGE="Aantal lijnen: $NUMBEROFPAGES"
				fi
				echo $MESSAGE
				
				if [[ $NUMBEROFPAGES -lt 3 ]]; then
					while read article
					do
						MESSAGE="There is a new article:"
						if [[ $SPEAKLANG == "nl" ]]; then
							MESSAGE="Er is een nieuw artikel:"
						fi
						
						article_underscore=`echo $article | sed -e 's/ /_/g'`
						echo "$MESSAGE $PROTOCOL$WIKI/wiki/$article_underscore"
						msg "$MESSAGE $PROTOCOL$WIKI/wiki/$article_underscore"
						
					done < diff.txt
				else
					MESSAGE="There are $NUMBEROFPAGES new pages in"
					if [[ $SPEAKLANG == "nl" ]]; then
						MESSAGE="Er zijn $NUMBEROFPAGES nieuwe pagina's in"
					fi
					msg "$MESSAGE $PROTOCOL$WIKI/wiki/$CATEGORY"
				fi
			fi
		else
			MESSAGE = "Not different from the last time"
			if [[ $SPEAKLANG == "nl" ]]; then
				MESSAGE="Niet anders dan de vorige keer."
			fi
			echo $MESSAGE
			
			if [[ $INFOMESSAGES == "true" ]] && [[ $IRCENABLED == "true" ]]; then
				msg $MESSAGE
			fi
		fi
	else
		MESSAGE = "Difference with last time is zero."
		if [[ $SPEAKLANG == "nl" ]]; then
			MESSAGE="Er is geen verschil met de vorige keer."
		fi
		echo $MESSAGE
		
		if [[ $INFOMESSAGES == "true" ]] && [[ $IRCENABLED == "true" ]]; then
			msg $MESSAGE
		fi
	fi

	rm diff.txt
	sleep $SECONDS
done
