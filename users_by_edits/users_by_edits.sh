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

AUFROM=""
LENGTH=500

urlencode() {
    # urlencode <string>

    local LANG=C
    local length="${#1}"
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
   	ENCUSERNAME=`urlencode "$username"`
   	
   	# First edit
	wget -O "firstedit-$ENCUSERNAME.json" --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&ucuser=$ENCUSERNAME&uclimit=1&ucdir=newer&format=json" 2&>/dev/null
    jq -r '.query.usercontribs[0].timestamp' firstedit-$ENCUSERNAME.json > "firstedit-$ENCUSERNAME.txt"
    
    FIRSTEDIT=""
    while read -r line; do
		FIRSTEDIT="$line"
		echo "First edit date for $username is $FIRSTEDIT"
		break
	done < "firstedit-$ENCUSERNAME.txt"
	rm "firstedit-$ENCUSERNAME.json"
	rm "firstedit-$ENCUSERNAME.txt"
    
	# Last edit
	wget -O "lastedit-$ENCUSERNAME.json" --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=usercontribs&ucuser=$ENCUSERNAME&uclimit=1&ucdir=older&format=json" 2&>/dev/null
    jq -r '.query.usercontribs[0].timestamp' lastedit-$ENCUSERNAME.json > "lastedit-$ENCUSERNAME.txt"
    
    LASTEDIT=""
    while read -r line; do
		LASTEDIT="$line"
		echo "Last edit date for $username is $LASTEDIT"
		break
	done < "lastedit-$ENCUSERNAME.txt"
    rm "lastedit-$ENCUSERNAME.json"
    rm "lastedit-$ENCUSERNAME.txt"
    
    # Log events
    ISBOT="false"
    wget -O "logevent-$ENCUSERNAME.json" --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&letype=rights&lelimit=500&letitle=User:$ENCUSERNAME&format=json" 2>/dev/null
    jq -r '.query.logevents[] | . as $parent | .params | tostring | select(contains("bot")) | $parent.title | split(":") | del(.[0]) | join(":")' logevent-$ENCUSERNAME.json | uniq > "logevent-$ENCUSERNAME.txt"
    while read -r line; do
		if [[ -n "$line" && "$line" != "null" ]]; then
			ISBOT="true"
		fi
		break
	done < "logevent-$ENCUSERNAME.txt"
	# Mark bots that were not detected in the logs that contain bot
	if [[ "$username" == *"bot"* || "$username" == *"Bot"* || "$username" == *"BoT"* || "$username" == *"BOT"* ]]; then
		ISBOT="true"
	fi
	
	# Mark bots that were not detected in the logs that don't contain bot
	if [[ "$username" == "MediaWiki message delivery" || "$username" == "CommonsDelinker" ]]; then
		ISBOT="true"
	fi
	
	# Unmark normal users as bot
	if [[ "$username" == "Robotje" || "$username" == "Brbotnl" || "$username" == *"boter"* || "$username" == *"Boter"* || "$username" == "Rozebottel" || "$username" == "Debot" || "$username" == "Botend" || "$username" == "Botaneiates" ]]; then
		ISBOT="false"
	fi
		
	echo "$username bot == $ISBOT"
    rm "logevent-$ENCUSERNAME.json"
    rm "logevent-$ENCUSERNAME.txt"
    
    # Fix some users (they only have deleted edits)
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
    
    # Write result for this user to file
    echo "{ \"name\": \"$username\", \"firstedit\": \"$FIRSTEDIT\", \"lastedit\": \"$LASTEDIT\", \"bot\": \"$ISBOT\" }," >> edit-dates.json
}

while [[ $LENGTH -eq 500 ]]
do
	rm api.php* 2>/dev/null
	wget --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=allusers&auprop=editcount|groups&aulimit=500&auwitheditsonly&format=json&aufrom=$AUFROM$ACTIVEONLY" 2&>/dev/null
	AUFROM=`jq -r '.continue.aufrom' api.php*`
	echo $AUFROM
	jq -r '.query.allusers[] | {name: .name, editcount: .editcount, groups: .groups}' api.php* >> result.json
	LENGTH=`jq -r '.query.allusers | length' api.php*`
done

echo "Convert single JSON objects into JSON array"
sed -i 's/}/},/g' result.json
# add [ and ] to make an array to the beginning and end of the file
cat result.json | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed -e '$s/,$/]/' > result-properly.json
resultproperly=`cat result-properly.json`
echo "[$resultproperly" > result-properly.json
#now make a TSV (sort first)
echo "Sorting..";
jq -r "sort_by(-.editcount)" result-properly.json > sorted-data.json

# Cleanup
rm result-properly.json 2>/dev/null
rm result.json 2>/dev/null
rm aufrom.txt 2>/dev/null
rm api.php* 2>/dev/null

##########################################################################################################################################
echo "Expanding JSON data with edit dates and bot data"
jq -r '.[] | [ .name ] | join("\n")' sorted-data.json | head -n$HIGHLIMIT > usernames.$HIGHLIMIT.txt

# Make the beginning
echo "[" > edit-dates.json

export -f urlencode
export -f doaction
export PROTOCOL=$PROTOCOL
export WIKI=$WIKI

cat "usernames.$HIGHLIMIT.txt" | parallel -P 16 doaction {}

# Make the end
sed -i edit-dates.json -e '$s/,$/]/'

# Cleanup
rm firstedit-*.json 2>/dev/null
rm lastedit-*.json 2>/dev/null
rm logevents-*.json 2>/dev/null

rm usernames.$HIGHLIMIT.txt

## Merge data
jq -s '[ .[0] + .[1] | group_by(.name)[] | select(length > 1) | add ]' edit-dates.json sorted-data.json > expanded-sorted-data.json

###########################################################################################################################################
echo "Generating "
jq -r '.[] | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-all-raw.json
jq -r '.[] | select((.bot | contains ("true")) or (.groups | tostring | contains ("bot"))) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-bots-raw.json
jq -r '.[] | select((.bot | contains ("false")) and (.groups | tostring | contains ("bot") | not)) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-normal-raw.json

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
