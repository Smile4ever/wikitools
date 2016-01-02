#!/bin/bash
#Last changed service = currently playing

ARRAY=("VLC Media Player" "YouTube" "Video Dailymotion")
rm list.txt
for ((i = 0; i < ${#ARRAY[@]}; i++)); do
	title=`wmctrl -l | grep -o "$HOSTNAME.*" | sed "s/$HOSTNAME //g" | grep -o ".* - ${ARRAY[$i]}"`
	#echo $title
	IFS=$(echo -en "\n\b")
	title=`printf "%s\n" $title | sed "s/Video Dailymotion/Dailymotion/g"`
	title=`printf "%s\n" $title | sed "s/ (Official Video)//g"`
	title=`printf "%s\n" $title | sed "s/~/-/g"`
	title=`printf "%s\n" $title | sed "s/:/-/g"`
	
	
	printf "%s\n" $title >> list.txt
	#cat list.txt
done

sort list.txt | uniq > uniqlist.txt
rm list.txt
tail -n +2 uniqlist.txt > list.txt
cat list.txt