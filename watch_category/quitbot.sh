#!/bin/bash
#echo "I'm leaving." > ~/irc/irc.freenode.net/in
if [[ $SPEAKLANG == "" ]]; then
	SPEAKLANG="$1"
fi

if [[ $SPEAKLANG == "nl" ]]; then
	echo "IRC-netwerk verlaten..."
else
	echo "Leaving IRC network..."
fi
cd
echo "/quit" > irc/irc.freenode.net/in &
#sudo pkill watch_category.sh