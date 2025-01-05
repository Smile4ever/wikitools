#!/bin/bash
# users_by_edits

if [[ $WIKI == "" ]]; then
	WIKI="https://nl.wikipedia.org"
fi

if [[ $LIMIT == "" ]]; then
	LIMIT=10000
fi

if [[ $HIGHLIMIT == "" ]]; then
	HIGHLIMIT=30000
fi

if [[ $ACTIVEONLY == "true" ]]; then
	ACTIVEONLY="&auactiveusers"
fi

if [[ $AUFROM == null ]]; then
	AUFROM=""
fi

if [[ $I18N_EDITS == "" ]]; then
	I18N_EDITS="bewerkingen"
fi

if [[ $I18N_USER == "" ]]; then
	I18N_USER="Gebruiker"
fi

LENGTHMAX=500
GLOBAL_LOGEVENTJSON="" # Global variable for storing log events JSON

urlencode() {
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

calculateIsBot() {
    # Take the username as the input parameter
    local username="$1" # ENCUSERNAME
    
	# Mark bots that were not detected in the logs that don't contain bot (known system bots)
	if [[ "$username" == "MediaWiki%20message%20delivery" || "$username" == "CommonsDelinker" || "$username" == "InternetArchiveBot" ]]; then
		echo "$ENCUSERNAME is a known system bot" >> calculateIsBots.txt
		echo "true|system"
		return 0
	fi

	# Mark unrecognised bots
	if [[ "$username" == "JAnDbot" || "$username" == "WillBot" || "$username" == "GhalyBot" || "$username" == "RobotTbc" || "$username" == "Erwin85Bot" || "$username" == "RobotMichiel1972" ]]; then
		echo "$username is a known bot" >> calculateIsBots.txt
		echo "true|knownbot"
		return 0
	fi

	# Unmark normal users as bot (known users, not bots)
	if [[ "$username" == "Robotje" || "$username" == "Brbotnl" || "$username" == *"boter"* || "$username" == *"Boter"* || "$username" == "Rozebottel" || "$username" == "Debot"
	|| "$username" == "Botend" || "$username" == "Botaneiates" || "$username" == "Br_bot" || "$username" == "Botje1974" || "$username" == "BobbyDeBot" || "$username" == "Dlibot"
	|| "$username" == "Hector Bottai" || "$username" == "Jeroenbottema" ]]; then
		echo "$username is a known non-bot" >> calculateIsBots.txt
		echo "false|knownuser"
		return 0
	fi

	# Bug: Ghgh is a bot. Matched: '[[Bot (computerprogramma)...]]'
	# Bug: Dup%20duitser3 is a bot. Matched: '{{Bot...}}' template -- {{Bots}} shouldn't be matched - should be okay
	# Bug: Ceescamel is a bot. Matched: '[[Bot (computerprogramma)...]]'
	# Bug: Bjelka is a bot. Matched: '[[Bot (computerprogramma)...]]'
	# Bug: Quizmaster12 is a bot. Matched: '[[Bot (computerprogramma)...]]'
	# Bug: GingerbreadmanNL is a bot. Matched: '{{Bot...}}' template -- {{BOT}} shouldn't be matched - should be okay
	# Bug: Barkruk%20Henkie is a bot. Matched: '[[Bot (computerprogramma)...]]'
	# Bug: Joshua6464 is a bot. Matched: '[[Bot (computerprogramma)...]]'

	if [[ "$username" == "Ghgh" || "$username" == "Ceescamel" || "$username" == "Bjelka" || "$username" == "Quizmaster12" || "$username" == "Barkruk%20Henkie" || "$username" == "Joshua6464" ]]; then
		echo "$username is a known non-bot (bug)" >> calculateIsBots.txt
		echo "false|knownuserbug"
		return 0
	fi

    # Fetch the wikitext of the user page using the MediaWiki API
    local response=$(curl -sS "$WIKI/w/api.php?action=query&prop=revisions&titles=User:${username}&rvslots=*&rvprop=content&formatversion=2&format=json")
    # Extract the content using jq
    local content=$(echo "$response" | jq -r '.query.pages[0].revisions[0].slots.main.content')
    local contentlimited=$(echo "$response" | jq -r '.query.pages[0].revisions[0].slots.main.content' | head -n 5)

	# Fetch the JSON response
	responseLogPatrolEvents=$(curl -sS "$WIKI/w/api.php?action=query&list=logevents&letype=patrol&leuser=${username}&lelimit=100&format=json")

	# Count the number of patrol log entries using jq
	patrolled_count=$(echo "$responseLogPatrolEvents" | jq '.query.logevents | length')

    # Check if the content contains "{{Bot"
	#if echo "$content" | grep -qi '{{Bot.*}}'; then
	if echo "$content" | grep -q '{{[Bb]ot[^s}]*}}'; then
		echo "$username is a bot. Matched: '{{Bot...}}' template" >> calculateIsBots.txt
		echo "true|template"
		return 0
	fi

	username_contains_bot="false"
	if [[ "$username" == *"bot"* || "$username" == *"Bot"* || "$username" == *"BoT"* || "$username" == *"BOT"* || "$username" == *"AWB"* ]]; then
		username_contains_bot="true"
	fi

	if [[ $username_contains_bot == "true" ]]; then
		if echo "$content" | grep -qi 'Crystal Clear action run.'; then
			echo "$username is a bot. Matched: Crystal Clear action run.png/svg" >> calculateIsBots.txt
			echo "true|icon"
			return 0
		fi
	fi

	username_endswith_bot="false"
	if [[ "$username" == *"bot" || "$username" == *"Bot" || "$username" == *"BoT" || "$username" == *"BOT" || "$username" == *"AWB" ]]; then
		username_endswith_bot="true"
	fi

	if [[ $patrolled_count -lt 10 || $username_endswith_bot == "true" ]]; then
		if echo "$content" | grep -qi '\b(bot van|de bot|the bot)\b'; then
			echo "$username is a bot. Matched: phrases like 'bot van', 'de bot', or 'the bot'" >> calculateIsBots.txt
			echo "true|phrase"
			return 0
		elif echo "$content" | grep -qi '\[\[Bot \(computerprogramma\)\|?.*?\]\]'; then
			echo "$username is a bot. Matched: '[[Bot (computerprogramma)...]]'" >> calculateIsBots.txt
			echo "true|linkcomputerprogramma"
			return 0
		elif echo "$content" | grep -qi '\[\[Wikipedia:Bot\]\]'; then
			echo "$username is a bot. Matched: '[[Wikipedia:Bot]]'" >> calculateIsBots.txt
			echo "true|linkbot"
			return 0
		elif echo "$content" | grep -qi '\[\[Wikipedia:Systeembots\]\]'; then
			echo "$username is a bot. Matched '[[Wikipedia:Systeembots]]'" >> calculateIsBots.txt
			echo "true|linksysteembot"
			return 0
		elif echo "$content" | grep -qi '\[\[Wikipedia:Bots\|?.*?\]\]'; then
			echo "$username is a bot. Matched: '[[Wikipedia:Bots...]]'" >> calculateIsBots.txt
			echo "true|linkbots"
			return 0
		fi
	fi
	
	if [[ $username_contains_bot == "true" ]]; then
		# Request to get revisions (up to 50)
		local responseRevisions=$(curl -sS "$WIKI/w/api.php?action=query&prop=revisions&titles=User:${username}&rvslots=*&rvprop=content&formatversion=2&format=json&rvlimit=100")

		# Count the number of revisions using jq
		local revision_count=$(echo "$responseRevisions" | jq '.query.pages[].revisions | length')
		
		if [ $revision_count -le 40 ]; then
			echo "$username is probably a bot, username contains bot (revisions $revision_count, marked as patrolled $patrolled_count)." >> calculateIsBots.txt
			echo "true|revisioncountlowcontainsbot"
			return 0
		else
			echo "$username is no bot (revisions $revision_count, marked as patrolled $patrolled_count), but username contains bot for some reason. Content was $contentlimited" >> calculateIsBots.txt
			echo "false|revisioncounttoohigh"
			return 0
		fi
	fi

	echo "$username is most likely a normal user and no bot (marked as patrolled $patrolled_count)" >> calculateIsBots.txt
	echo "false|likelynormaluser"
}

doaction() {
    username="$1"
   	ENCUSERNAME=`urlencode "$username"`
   	#echo "Retrieve first edit, last edit and bot flag for $username" # -> $ENCUSERNAME
   
   	# First edit
   	#echo "Fetching first edit for $ENCUSERNAME.."
   	FIRSTEDITJSON=$(curl -sS "$WIKI/w/api.php?action=query&list=usercontribs&uclimit=1&ucdir=newer&ucuser=$ENCUSERNAME&format=json")
   	FIRSTEDIT=$(echo $FIRSTEDITJSON | jq -r '.query.usercontribs[0].timestamp')
   	if [[ $FIRSTEDIT == "null" || $FIRSTEDIT == "" ]]; then
		#echo "Fetching from log events (first edit).."
		FIRSTEDITLOGEVENTJSON=$(curl -sS "$WIKI/w/api.php?action=query&list=logevents&lelimit=1&ledir=newer&leuser=$ENCUSERNAME&format=json")
		FIRSTEDIT=$(echo $FIRSTEDITLOGEVENTJSON | jq -r '.query.logevents[0].timestamp')
		if [[ $FIRSTEDIT == "null" ]]; then
			FIRSTEDIT="?"
		fi
	fi

    # LAST edit
    #echo "Fetching last edit for $ENCUSERNAME.."
   	LASTEDITJSON=$(curl -sS "$WIKI/w/api.php?action=query&list=usercontribs&ucuser=$ENCUSERNAME&uclimit=1&ucdir=older&format=json")
   	LASTEDIT=$(echo $LASTEDITJSON | jq -r '.query.usercontribs[0].timestamp') 
	if [[ $LASTEDIT == "null" || $LASTEDIT == "" ]]; then
		#echo "Fetching from log events (last edit).."
		LASTEDITLOGEVENTJSON=$(curl -sS "$WIKI/w/api.php?action=query&list=logevents&lelimit=1&ledir=older&leuser=$ENCUSERNAME&format=json")
		LASTEDIT=$(echo $LASTEDITLOGEVENTJSON | jq -r '.query.logevents[0].timestamp')
		if [[ $LASTEDIT == "null" ]]; then
			LASTEDIT="?"
		fi
	fi

    # Log events  
    ISBOT="false"

    # Parse log events from the global variable for the current user
    LOGEVENT=$(echo $GLOBAL_LOGEVENTJSON | jq -r --arg userParam "$username" '.query.logevents[] | select(.user == $userParam) | .params | tostring | select(contains("bot"))')

    if [ $? -ne 0 ]; then
        echo "jq crashed or something else went wrong while parsing logevents for $username"
        exit $?
    fi

    if [[ -n "$LOGEVENT" && "$LOGEVENT" != "null" ]]; then
        echo "User $username has bot related log events." >> calculateIsBots.txt
        ISBOT="true"
    fi
	
	# If logevents were always available and all bots would have a bot flag, we wouldn't need calculateIsBot
	if [[ "$ISBOT" == "false" ]]; then
		ISBOTRESULT=$(calculateIsBot "$ENCUSERNAME")
	fi

	# Split the result into isbot and reason
	IFS='|' read -r ISBOT ISBOT_REASON <<< "$ISBOTRESULT"
	
	tput sc  # Save current cursor position
	if [[ "$ISBOT" == "true" ]]; then
		echo "Bot $username $ISBOT_REASON"
	else
		echo "User $username $ISBOT_REASON"
	fi
    tput rc  # Restore saved cursor position

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
	# Initialize the continue parameter for pagination
	lecontinue=""

	echo "Fetching all log events for users, handling pagination with 'lecontinue'..."

	LENGTH=$LENGTHMAX
	while [[ $LENGTH -eq $LENGTHMAX ]]
	do
		if [ -z "$lecontinue" ]; then
			response=$(curl -sS "$WIKI/w/api.php?action=query&list=logevents&letype=rights&lelimit=$LENGTHMAX&format=json")
		else
			ENCLECONTINUE=`urlencode "$lecontinue"`
			response=$(curl -sS "$WIKI/w/api.php?action=query&list=logevents&letype=rights&lelimit=$LENGTHMAX&lecontinue=$ENCLECONTINUE&format=json")
		fi
		
		# Check if the request failed
		if [ -z "$response" ]; then
			echo "Failed to fetch log events, ELCONTINUE was $ENCLECONTINUE."
			exit 1
		fi

		# Append the current batch of log events to GLOBAL_LOGEVENTJSON
		if [ -z "$GLOBAL_LOGEVENTJSON" ]; then
			GLOBAL_LOGEVENTJSON="$response"
			echo $GLOBAL_LOGEVENTJSON > GLOBAL_LOGEVENT.json
		else
			# Merge current batch into the global JSON
			GLOBAL_LOGEVENTJSON=$(echo "$GLOBAL_LOGEVENTJSON" "$response" | jq -s '.[0].query.logevents += .[1].query.logevents | .[0]')
			echo $GLOBAL_LOGEVENTJSON > GLOBAL_LOGEVENT.json
		fi

		LENGTH=$(echo "$response" | jq -r '.query.logevents | length')

		echo -n "Downloaded $LENGTH log events starting from $lecontinue, continuing to "
		# Check if there is more data to fetch (pagination)
		lecontinue=$(echo "$response" | jq -r '.continue.lecontinue')
		echo "$lecontinue"
	done

	echo "Finished fetching all log events."

	LENGTH=$LENGTHMAX
	while [[ $LENGTH -eq $LENGTHMAX ]]
	do
		#echo "Updating, starting from $AUFROM.."
		cp api.php* old.php 2>/dev/null
		rm -f api.php*
				
		ENCAUFROM=`urlencode "$AUFROM"`
		curl -sS --retry 5 --retry-delay 0 --retry-connrefused --insecure --user-agent "usersbyedits tool by Smile4ever" --max-time 15 -o api.php "$WIKI/w/api.php?action=query&list=allusers&auprop=editcount|groups&aulimit=$LENGTHMAX&auwitheditsonly&format=json&aufrom=$ENCAUFROM$ACTIVEONLY"

		if [ $? -ne 0 ]
		then
			echo "Failed to download from $AUFROM. Start the script again. It will pickup where it left off. The exit code was $?"
			mv old.php api.php
			exit $?
		fi
		
		LENGTH=`jq -r '.query.allusers | length' api.php*`
		echo -n "Downloaded $LENGTH users with editcount starting from $AUFROM, continuing to "
		rm -f old.php
		AUFROM=`jq -r '.continue.aufrom' api.php*`
		echo "$AUFROM"

		#jq -r '.query.allusers[] | {name: .name, editcount: .editcount, groups: .groups}' api.php* >> result.json
		jq -r '.query.allusers[] | select(.editcount >= 100) | {name: .name, editcount: .editcount, groups: .groups}' api.php* >> result.json
	done

	# Cleanup getting data
	rm -f aufrom.txt
	rm -f api.php*

	echo "Convert single JSON objects into JSON array"
	jq -s . result.json > result-properly.json
	
	# Sort to be able to make result files
	echo "Sorting..";

	# Cleanup sorting data
	if jq -r 'sort_by(-.editcount)' result-properly.json > sorted-data.json; then
		echo "Sorting successful. Cleaning up intermediate files."
		rm -f result.json
		rm -f result-properly.json
	else
		echo "Error: Sorting failed. Keeping intermediate files for debugging and to continue later if desired."
		exit 1
	fi
fi

##########################################################################################################################################
if [ ! -f "edit-dates.json" ]; then
	echo "Expanding JSON data with edit dates and bot data (highlimit is $HIGHLIMIT)"
	if jq -r '.[] | [ .name ] | join("\n")' sorted-data.json | head -n$HIGHLIMIT > usernames.$HIGHLIMIT.txt; then
		echo "Succesfully made list usernames.$HIGHLIMIT.txt"
	else
		echo "Succesfully make list usernames.$HIGHLIMIT.txt"
		rm -f usernames.$HIGHLIMIT.txt
		exit 1
	fi

	# Make the beginning
	echo "[" > edit-dates.json

	export -f urlencode
	export -f doaction
	export -f calculateIsBot
	export WIKI=$WIKI

	total=$(wc -l < "usernames.$HIGHLIMIT.txt")  # Count total usernames
	completed=0  # Initialize completed counter

	echo "$total"

	while IFS= read -r -d '' username; do
		doaction "$username" &
		if [[ $(jobs -r -p | wc -l) -ge 30 ]]; then
			wait -n  # Wait for any job to finish
			((completed++))
        	echo -ne "\rProgress: $completed/$total completed"
		fi
	done < <(tr -d '\r' < "usernames.$HIGHLIMIT.txt" | tr '\n' '\0')

	wait # Wait for all jobs to finish

	# Make the end (replace comma by closing square bracket)
	sed -i edit-dates.json -e '$s/,$/]/'
fi

## Check data and exit if needed
if grep -q "\"null\"" "edit-dates.json"; then
	echo "Please correct any null occurences in edit-dates.json before starting the script again."
	exit 1
fi

## Merge data
echo "Merging data"
jq -s '[ .[0] + .[1] | group_by(.name)[] | select(length > 1) | add ]' edit-dates.json sorted-data.json > expanded-sorted-data.json
if [ $? -ne 0 ]; then
	echo "jq crashed or something else went wrong while merging data"
	exit $?
fi

###########################################################################################################################################
echo "Generating"

jq -r '.[] | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-all-raw.json
jq -r '.[] | if .bot == null then .bot |="false" else . end | select((.bot | contains ("true")) or (.groups | tostring | contains ("bot"))) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-bots-raw.json
jq -r '.[] | if .bot == null then .bot |="false" else . end | select((.bot | contains ("false")) and (.groups | tostring | contains ("bot") | not)) | {name: .name, firstedit: .firstedit, lastedit: .lastedit, editcount: .editcount}' expanded-sorted-data.json | jq -s . > usernames-normal-raw.json

jq -r 'sort_by(-.editcount)' usernames-all-raw.json > usernames-all.json
jq -r 'sort_by(-.editcount)' usernames-bots-raw.json > usernames-bots.json
jq -r 'sort_by(-.editcount)' usernames-normal-raw.json > usernames-normal.json

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

jq -r '.[] | [ "# {{intern|1=title='""$I18N_USER""':", (.name | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - '""$I18N_EDITS""': ", (.editcount|tostring) ] | join("")' usernames-all.json > usernames-all-wikitext.txt
sed -i 's/$/)/' usernames-all-wikitext.txt

jq -r '.[] | [ "# {{intern|1=title='""$I18N_USER""':", (.name | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - '""$I18N_EDITS""': ", (.editcount|tostring) ] | join("")' usernames-bots.json | cat > usernames-bots-wikitext.txt
sed -i 's/$/)/' usernames-bots-wikitext.txt

jq -r '.[] | [ "# {{intern|1=title='""$I18N_USER""':", (.name | sub(" "; "_")), "|2=", .name, "}} (", .firstedit, " - ", .lastedit, " - '""$I18N_EDITS""': ", (.editcount|tostring) ] | join("")' usernames-normal.json | cat > usernames-normal-wikitext.txt
sed -i 's/$/)/' usernames-normal-wikitext.txt

###########################################################################################################################################
echo "Creating limited wikitext files"

head -n $LIMIT usernames-all-wikitext.txt > usernames-all-wikitext.$LIMIT.txt
head -n $LIMIT usernames-bots-wikitext.txt > usernames-bots-wikitext.$LIMIT.txt
head -n $LIMIT usernames-normal-wikitext.txt > usernames-normal-wikitext.$LIMIT.txt

echo "Done"
