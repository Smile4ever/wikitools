#!/bin/bash
if [[ $PROTOCOL == "" ]]; then
	PROTOCOL="https://"
fi
if [[ $WIKI == "" ]]; then
	WIKI="nl.wikipedia.org"
fi

if [[ $LIMIT == "" ]]; then
	LIMIT=10000
fi

if [[ $HIGHLIMIT == "" ]]; then
	HIGHLIMIT=20000
fi

if [[ $ACTIVEONLY == "true" ]]; then
	ACTIVEONLY="&auactiveusers"
fi

if [[ $AUFROM == null ]]; then
	AUFROM=""
fi

LENGTH=500

urlencode() {
    # urlencode <string>

    local LANG=C
    local length="${#1}"
    echo "Length is $length for ${#1}"

    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;; 
        esac
    done
}

doaction() {
    username="$1"
   	ENCUSERNAME="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$username")"
   	echo "$username -> $ENCUSERNAME"
   
   	# First edit
   	echo "Fetching first edit.."
   	echo "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&uclimit=1&ucdir=newer&ucuser=$ENCUSERNAME&format=json"
   	FIRSTEDITJSON=$(curl -s "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&uclimit=1&ucdir=newer&ucuser=$ENCUSERNAME&format=json")
   	FIRSTEDIT=$(echo $FIRSTEDITJSON | jq -r '.query.usercontribs[0].timestamp')
   	if [[ $FIRSTEDIT == "null" ]]; then
		echo "Fetching from log events (first edit).."
		FIRSTEDITLOGEVENTJSON=$(curl -s "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&lelimit=2&ledir=older&leuser=$ENCUSERNAME&format=json")
		FIRSTEDIT=$(echo $FIRSTEDITLOGEVENTJSON | jq -r '.query.logevents[1].timestamp')
		if [[ $FIRSTEDIT == "null" ]]; then
			FIRSTEDIT="?"
		fi
	fi
    echo $FIRSTEDIT

    # LAST edit
    echo "Fetching last edit.."
    echo "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&ucuser=$ENCUSERNAME&uclimit=1&ucdir=older&format=json"
   	LASTEDITJSON=$(curl -s "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&ucuser=$ENCUSERNAME&uclimit=1&ucdir=older&format=json")
   	LASTEDIT=$(echo $LASTEDITJSON | jq -r '.query.usercontribs[0].timestamp') 
	if [[ $LASTEDIT == "null" ]]; then
		echo "Fetching from log events (last edit).."
		LASTEDITLOGEVENTJSON=$(curl -s "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&lelimit=1&ledir=older&leuser=$ENCUSERNAME&format=json")
		LASTEDIT=$(echo $LASTEDITLOGEVENTJSON | jq -r '.query.logevents[0].timestamp')
		if [[ $LASTEDIT == "null" ]]; then
			LASTEDIT="?"
		fi
	fi
	echo $LASTEDIT

    # Log events
    LOGEVENTJSON=$(curl -s "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&letype=rights&lelimit=500&letitle=User:$ENCUSERNAME&format=json")
    SIZE=$(echo $LOGEVENTJSON | wc -c | cut -f1 -d' ')
    echo $SIZE
    
    ISBOT="false"

    if [ "$SIZE" -lt 50 ]; then
		echo "Set ISBOT=false. $ENCUSERNAME has no log events, which means no extra assigned rights such as bot."
		echo "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&letype=rights&lelimit=500&letitle=User:$ENCUSERNAME&format=json"
	else
		LOGEVENT=$(echo $LOGEVENTJSON | jq -r '.query.logevents[] | . as $parent | .params | tostring | select(contains("bot")) | $parent.title | split(":") | del(.[0]) | join(":")' | uniq ) 
		if [ $? -ne 0 ]; then
			echo "jq crashed or something else went wrong"
			exit $?
		fi
		
		echo $LOGEVENT > "logevent-$ENCUSERNAME.txt"
		
		while read -r line; do
			if [[ -n "$line" && "$line" != "null" ]]; then
				ISBOT="true"
			fi
			break
		done < "logevent-$ENCUSERNAME.txt"
		
		rm "logevent-$ENCUSERNAME.txt"
		
		# Mark bots that were not detected in the logs that contain bot
		if [[ "$username" == *"bot"* || "$username" == *"Bot"* || "$username" == *"BoT"* || "$username" == *"BOT"* ]]; then
			ISBOT="true"
		fi
		
		# Mark bots that were not detected in the logs that don't contain bot
		if [[ "$username" == "MediaWiki message delivery" || "$username" == "CommonsDelinker" ]]; then
			ISBOT="true"
		fi
		
		# Unmark normal users as bot
		if [[ "$username" == "Robotje" || "$username" == "Brbotnl" || "$username" == *"boter"* || "$username" == *"Boter"* || "$username" == "Rozebottel" || "$username" == "Debot" || "$username" == "Botend" || "$username" == "Botaneiates" || "$username" == "Br_bot" || "$username" == "Botje1974" || "$username" == "BobbyDeBot" || "$username" == "Dlibot" ]]; then
			ISBOT="false"
		fi
	fi
	
	if [[ "$ISBOT" == "true" ]]; then
		echo "Bot with firstedit $FIRSTEDIT and lastedit $LASTEDIT"
	else
		echo "User with firstedit $FIRSTEDIT and lastedit $LASTEDIT"
	fi
	echo ""
    
    # Fix some users for nl.wikipedia.org (they only have deleted edits)
    if [[ "$username" == "Jclcoosemans" ]]; then
		FIRSTEDIT = "2012-04-01T08:04:00Z"
		LASTEDIT = "2012-04-15T08:11:00Z"
    fi
    
    if [[ "$username" == "Gilles Pierrot" ]]; then
		FIRSTEDIT = "2016-10-05T08:40:00Z"
		LASTEDIT = "2016-10-21T17:20:00Z"
    fi
    
    if [[ "$username" == "JWHOP" ]]; then
		FIRSTEDIT = "2012-11-21T08:09:00Z"
		LASTEDIT = "2012-11-27T15:21:00Z"
    fi
    
    if [[ "$username" == "Avanthof" ]]; then
		FIRSTEDIT = "2014-05-14T14:25:00Z"
		LASTEDIT = "2014-05-14T20:19:00Z"
    fi
    
    if [[ "$username" == "Google1999" ]]; then
		FIRSTEDIT = "2010-10-02T15:15:00Z"
		LASTEDIT = "2010-10-03T16:54:00Z"
    fi
    
     if [[ "$username" == "Jordidegroot" ]]; then
		FIRSTEDIT = "2016-06-08T08:20:00Z"
		LASTEDIT = "2016-06-16T10:48:00Z"
    fi
    
     if [[ "$username" == "Jet boerrigter" ]]; then
		FIRSTEDIT = "2015-11-11T14:42:00Z"
		LASTEDIT = "2015-11-16T18:34:00Z"
    fi
    
    username=$(echo "$username" | sed --expression='s/"/\\"/g')
    
    # Write result for this user to file
    echo "{ \"name\": \"$username\", \"firstedit\": \"$FIRSTEDIT\", \"lastedit\": \"$LASTEDIT\", \"bot\": \"$ISBOT\" }," >> edit-dates.json
}

if test -n "$(find . -maxdepth 1 -name 'api.php*' -print -quit)"
then
	AUFROM=`jq -r '.continue.aufrom' api.php*`
fi

if [ -f "result.json" ]; then
	if [ -z "$AUFROM" ]; then
		echo "AUFROM is empty, but the file result.json already exists. Pass AUFROM as a parameter to the script with the value of .continue.aufrom."
		exit 1
	fi
fi

if [ ! -f "sorted-data.json" ]; then
	#allLetters=([a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8 [i]=9 [j]=10 [k]=11 [l]=12 [m]=13 [n]=14 [o]=15 [p]=16 [q]=17 [r]=18 [s]=19 [t]=20 [u]=21 [v]=22 [w]=23 [x]=24 [y]=25 [z]=26)
	#"a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z")

	while [[ $LENGTH -eq 500 ]]
	do
		echo "Updating, starting from $AUFROM.."
		cp api.php* old.php
		rm api.php* 2>/dev/null
		wget --timeout=15 --tries=5 --waitretry=0 --retry-connrefused --no-check-certificate --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=allusers&auprop=editcount|groups&aulimit=500&auwitheditsonly&format=json&aufrom=$AUFROM$ACTIVEONLY" #2&>/dev/null

		if [ $? -ne 0 ]
		then
			
			echo "Failed to download from $AUFROM. Start the script again. It will pickup where it left off."
			mv old.php api.php
			exit $?
		fi
		echo -n "Downloaded 500 items starting from $AUFROM, continuing to "
		rm old.php
		AUFROM=`jq -r '.continue.aufrom' api.php*`
		echo "$AUFROM"
		
		#FIRSTLETTER="${AUFROM:0:1}"
		#echo $FIRSTLETTER
		#echo ${myArray[$FIRSTLETTER]}

		jq -r '.query.allusers[] | {name: .name, editcount: .editcount, groups: .groups}' api.php* >> result.json
		LENGTH=`jq -r '.query.allusers | length' api.php*`
	done

	echo "Convert single JSON objects into JSON array"
	sed -i 's/}/},/g' result.json
	# add [ and ] to make an array to the beginning and end of the file
	cat result.json | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed -e '$s/,$/]/' > result-properly.json
	resultproperly=`cat result-properly.json`
	echo "[$resultproperly" > result-properly.json
	#sort to be able to make result files
	echo "Sorting..";
	jq -r "sort_by(-.editcount)" result-properly.json > sorted-data.json

	# Cleanup
	rm result-properly.json 2>/dev/null
	rm result.json 2>/dev/null
	rm aufrom.txt 2>/dev/null
	rm api.php* 2>/dev/null

fi

##########################################################################################################################################
if [ ! -f "edit-dates.json" ]; then
	echo "Expanding JSON data with edit dates and bot data"
	jq -r '.[] | [ .name ] | join("\n")' sorted-data.json | head -n$HIGHLIMIT > usernames.$HIGHLIMIT.txt

	# Make the beginning
	echo "[" > edit-dates.json

	export -f urlencode
	export -f doaction
	export PROTOCOL=$PROTOCOL
	export WIKI=$WIKI

	parallel --version
	if [ $? -ne 0 ]
	then
		echo "Install parallel and after that, start the script again"
		exit $?
	fi

	echo "Highlimit is $HIGHLIMIT"
	wc -l "usernames.$HIGHLIMIT.txt" 
	cat "usernames.$HIGHLIMIT.txt" | parallel --gnu -P 20 doaction {}

	# Make the end (replace comma by closing square bracket)
	sed -i edit-dates.json -e '$s/,$/]/'

	# Cleanup
	#rm usernames.$HIGHLIMIT.txt
fi

## Check data and exit if needed
if grep -q "\"null\"" "edit-dates.json"; then
	echo "Please correct any null occurences before starting the script again."
	exit 1
fi

## Merge data
echo "Merging data"
jq -s '[ .[0] + .[1] | group_by(.name)[] | select(length > 1) | add ]' edit-dates.json sorted-data.json > expanded-sorted-data.json
if [ $? -ne 0 ]; then
	echo "jq crashed or something else went wrong"
	exit $?
fi

###########################################################################################################################################
echo "Generating "
jq -r '.[] | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-all-raw.json
jq -r '.[] | if .bot == null then .bot |="false" else . end | select((.bot | contains ("true")) or (.groups | tostring | contains ("bot"))) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-bots-raw.json
jq -r '.[] | if .bot == null then .bot |="false" else . end | select((.bot | contains ("false")) and (.groups | tostring | contains ("bot") | not)) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-normal-raw.json

jq -r "sort_by(-.editcount)" usernames-all-raw.json > usernames-all.json
jq -r "sort_by(-.editcount)" usernames-bots-raw.json > usernames-bots.json
jq -r "sort_by(-.editcount)" usernames-normal-raw.json > usernames-normal.json

rm usernames-all-raw.json
rm usernames-bots-raw.json
rm usernames-normal-raw.json

###########################################################################################################################################
echo "Creating usernames-*.tsv files"

jq -r '.[] | [ .name, .firstedit, .lastedit, .editcount|tostring ] | join("\t")' usernames-all.json > usernames-all.tsv
jq -r '.[] | [ .name, .firstedit, .lastedit, .editcount|tostring ] | join("\t")' usernames-bots.json > usernames-bots.tsv
jq -r '.[] | [ .name, .firstedit, .lastedit, .editcount|tostring ] | join("\t")' usernames-normal.json > usernames-normal.tsv

###########################################################################################################################################
echo "Creating wikitext files"

jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.name | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - bewerkingen: ", .editcount|tostring ] | join("\t")' usernames-all.json | cat > usernames-all-wikitext.txt
sed -i 's/$/\t)/' usernames-all-wikitext.txt

jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.name | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - bewerkingen: ", .editcount|tostring ] | join("\t")' usernames-bots.json | cat > usernames-bots-wikitext.txt
sed -i 's/$/\t)/' usernames-bots-wikitext.txt

jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.name | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - bewerkingen: ", .editcount|tostring ] | join("\t")' usernames-normal.json | cat > usernames-normal-wikitext.txt
sed -i 's/$/\t)/' usernames-normal-wikitext.txt

###########################################################################################################################################
echo "Creating limited wikitext files"
sed $'s/\t//g' usernames-all-wikitext.txt | head -n$LIMIT > usernames-all-wikitext.$LIMIT.txt
sed $'s/\t//g' usernames-bots-wikitext.txt | head -n$LIMIT > usernames-bots-wikitext.$LIMIT.txt
sed $'s/\t//g' usernames-normal-wikitext.txt | head -n$LIMIT > usernames-normal-wikitext.$LIMIT.txt

echo "Done"
