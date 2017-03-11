#!/usr/bin/env bash

# nocat.sh 0.1
# Geoffrey De Belie
# Based on file upload example on https://www.mediawiki.org/wiki/API:Client_code/Bash

#Needs curl, wget, jq, base64 (from coreutils), openssl, head, tail

#Settings
WIKIAPI="https://nl.wikipedia.org/w/api.php"
EDIT="true"
#End of settings block

CONFIGPASSWORD="config/password.txt"
CONFIGUSER="config/username.txt"

mkdir config 2>/dev/null

if [[ ! -f "${CONFIGPASSWORD}" ]]; then
	echo "Welcome to nocat.sh"
	echo "The WIKIAPI is currently $WIKIAPI"
	echo "" 
	read -p "Username: " username
	echo -n "$username" > "${CONFIGUSER}"
	echo "Your username has been saved in the file ${CONFIGUSER}"

	read -s -p "Password: " password
	openssl enc -base64 <<< "$password" | tr -d '\n' | tr -d '\r' > "${CONFIGPASSWORD}"
	echo "Your password has been saved in the file ${CONFIGPASSWORD} using base64 encoding."

fi

USERNAME=$(cat ${CONFIGUSER})
USERPASS=$(cat ${CONFIGPASSWORD} | base64 --decode)
cookie_jar="data/wikicj" #Will store file in wikifile

rawurlencode() {
	ENCODED="${1//\&/\%26}" #replace ampersand by %26
	echo "${ENCODED}"
}

while true
do
    date +"%T"
	mkdir data 2>/dev/null

	RCSTART=$(date -d '2 hours ago' "+%Y-%m-%dT%H:%M:%S.000Z")
	NOCAT=$(date +"%Y|%m|%d")
	NOCAT="

{{nocat||${NOCAT}}}"

	if [[ $EDIT == "true" ]]; then
		echo "UTF8 check: ☠"
		#################login
		echo "Logging into $WIKIAPI as $USERNAME..."

		###############
		#Login part 1
		#printf "%s" "Logging in (1/2)..."
		echo "Get login token..."
		CR=$(curl -S \
			--location \
			--retry 2 \
			--retry-delay 5\
			--cookie $cookie_jar \
			--cookie-jar $cookie_jar \
			--user-agent "nocat.sh by Smile4ever" \
			--keepalive-time 60 \
			--header "Accept-Language: en-us" \
			--header "Connection: keep-alive" \
			--compressed \
			--request "GET" "${WIKIAPI}?action=query&meta=tokens&type=login&format=json")

		echo "$CR" | jq .
			
		rm login.json 2>/dev/null
		echo "$CR" > data/login.json
		TOKEN=$(jq --raw-output '.query.tokens.logintoken' data/login.json)
		TOKEN="${TOKEN//\"/}" #replace double quote by nothing

		#Remove carriage return!
		printf "%s" "$TOKEN" > data/token.txt
		TOKEN=$(cat data/token.txt | sed 's/\r$//')


		if [ "$TOKEN" == "null" ]; then
			echo "Getting a login token failed."
			exit	
		else
			echo "Login token is $TOKEN"
			echo "-----"
		fi

		###############
		#Login part 2
		echo "Logging in..."
		CR=$(curl -S \
			--location \
			--cookie $cookie_jar \
			--cookie-jar $cookie_jar \
			--user-agent "nocat.sh by Smile4ever" \
			--keepalive-time 60 \
			--header "Accept-Language: en-us" \
			--header "Connection: keep-alive" \
			--compressed \
			--data-urlencode "username=${USERNAME}" \
			--data-urlencode "password=${USERPASS}" \
			--data-urlencode "rememberMe=1" \
			--data-urlencode "logintoken=${TOKEN}" \
			--data-urlencode "loginreturnurl=http://en.wikipedia.org" \
			--request "POST" "${WIKIAPI}?action=clientlogin&format=json")

		echo "$CR" | jq .

		STATUS=$(echo $CR | jq '.clientlogin.status')
		if [[ $STATUS == *"PASS"* ]]; then
			echo "Successfully logged in as $USERNAME, STATUS is $STATUS."
			echo "-----"
		else
			echo "Unable to login, is logintoken ${TOKEN} correct?"
			exit
		fi

		###############
		#Get edit token
		echo "Fetching edit token..."
		CR=$(curl -S \
			--location \
			--cookie $cookie_jar \
			--cookie-jar $cookie_jar \
			--user-agent "nocat.sh by Smile4ever" \
			--keepalive-time 60 \
			--header "Accept-Language: en-us" \
			--header "Connection: keep-alive" \
			--compressed \
			--request "POST" "${WIKIAPI}?action=query&meta=tokens&format=json")

		echo "$CR" | jq .
		echo "$CR" > data/edittoken.json
		EDITTOKEN=$(jq --raw-output '.query.tokens.csrftoken' data/edittoken.json)
		rm data/edittoken.json

		EDITTOKEN="${EDITTOKEN//\"/}" #replace double quote by nothing

		#Remove carriage return!
		printf "%s" "$EDITTOKEN" > data/edittoken.txt
		EDITTOKEN=$(cat data/edittoken.txt | sed 's/\r$//')

		if [[ $EDITTOKEN == *"+\\"* ]]; then
			echo "Edit token is: $EDITTOKEN"
		else
			echo "Edit token not set."
			echo "EDITTOKEN was {EDITTOKEN}"
			exit
		fi
	fi

	RECENTCHANGES="data/recentchanges.json"
	RECENTCHANGESTXT="data/recentchanges.txt"
	RECENTLOGS="data/recentlogs.json"
	CURRENTCATS="data/current-categories.json"
	CURRENTCATSTXT="data/current-categories.txt"
	PAGES="list-pages.txt"
	LISTEDITEDPAGES="list-editedpages.txt"

	rm $PAGES 2>/dev/null
	
	wget "https://nl.wikipedia.org/w/api.php?action=query&list=recentchanges&rcprop=title|user&rcnamespace=0&rctype=new&rclimit=50&rcshow=!redirect&format=json&rcstart=${RCSTART}" -O $RECENTCHANGES >/dev/null 2>&1
	jq -r ".query.recentchanges[] | .title" $RECENTCHANGES > $RECENTCHANGESTXT
	wget "https://nl.wikipedia.org/w/api.php?action=query&list=logevents&letype=move&lelimit=50&format=json" -O $RECENTLOGS >/dev/null 2>&1
	jq -r ".query.logevents[] | .title" $RECENTLOGS | grep -v ":" >> $RECENTCHANGESTXT
	
	IFS=$'\n'
	for article in $(cat $RECENTCHANGESTXT | tr -d '\r')    
	do
		articleClean=$article
		#echo "Processing $article"
		article="${article// /_}"
		#article="${article//\r/}"
		
		echo "Downloading category info for $articleClean.."
		wget "https://nl.wikipedia.org/w/api.php?action=query&titles=$article&prop=categories&format=json&clshow=!hidden" -O $CURRENTCATS >/dev/null 2>&1
		
		#cat $CURRENTCATS
		#echo ""

		#Key parsen met jq:
		jq -r '.query.pages | .. | .title? | select(.)' $CURRENTCATS > $CURRENTCATSTXT
		echo "Looking for categories"
		COUNTVISIBLE=$(cat $CURRENTCATSTXT | grep -v ":Wikipedia:" | wc -l)
		COUNTVISIBLE=$(expr $COUNTVISIBLE - 1)
		COUNTHIDDEN=$(cat $CURRENTCATSTXT | grep ":Wikipedia:" | wc -l)
		COUNTALL=$(expr $COUNTVISIBLE + $COUNTHIDDEN)
		echo $COUNTALL categories, including $COUNTHIDDEN hidden categories
		
		echo "Checking if talkpage has been edited"
		wget "https://nl.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&continue=%7C%7C&titles=Overleg+gebruiker%3A${USERNAME}&converttitles=1&rvprop=timestamp&rvlimit=1" -O data/date.json >/dev/null 2>&1
	
		TODATE=$(date -d '90 minutes ago' "+%s")
		COND=$(grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' data/date.json)
		CONDUNIX=$(date -d "$COND" '+%s')
		
		if [ $CONDUNIX -gt $TODATE ]; then
			echo "Bot has stopped, because it's talkpage has been edited in the last 30 minutes."
			rm -rf data
			exit
		fi 
		
		if [[ $COUNTVISIBLE -eq 0 ]]; then	
			if [[ $EDIT == "true" ]]; then
				article=$( rawurlencode "$article" )
				CR=$(curl -S \
					--location \
					--retry 2 \
					--retry-delay 5\
					--cookie $cookie_jar \
					--cookie-jar $cookie_jar \
					--user-agent "nocat.sh by Smile4ever" \
					--keepalive-time 60 \
					--header "Accept-Language: en-us" \
					--header "Connection: keep-alive" \
					--compressed \
					--request "GET" "${WIKIAPI}?action=query&prop=revisions&titles=${article}&rvprop=timestamp|user|comment|content&format=json")

				#echo "$CR" | jq .
				CONTENT=$(echo $CR | jq -r '.query.pages')
				
				if [[ $CONTENT == *'missing":'* ]]; then
					echo "Malformed title"
					continue
				fi
				
				if [[ $CONTENT == *'invalidreason'* ]]; then
					echo "Invalid reason, content was"
					echo $CONTENT
					continue
				fi
				
				CONTENTLENGTH=$(echo $CONTENT | wc -l)
				if [[ $CONTENTLENGTH -eq 0 ]] || [[ $CONTENTLENGTH -eq 1 ]]; then
					echo "Skipping page with CONTENTLENGTH ${CONTENTLENGTH} (redirect or vandalism page)"
					continue
				fi
				
				if [[ $CONTENT == *"{{nocat"* ]] || [[ $CONTENT == *"{{Nocat"* ]]; then
					echo "{{nocat}} is already on this page"
					continue
				fi
				
				if [[ $CONTENT == *"{{nobots"* ]] || [[ $CONTENT == *"{{Nobots"* ]]; then
					echo "{{nobots}} is on this page"
					continue
				fi
				
				if [[ $CONTENT == *"{{bots|deny=all"* ]] || [[ $CONTENT == *"{{Bots|deny=all"* ]]; then
					echo "{{nobots}} is on this page"
					continue
				fi
				
				if [[ $CONTENT == *"[[Categor"* && $CONTENT != *":Wikipedia:"* ]] || [[ $CONTENT == *"[[categor"* && $CONTENT != *":wikipedia:"* ]]; then
					echo "Has already a category"
					continue
				fi
				
				if [[ $CONTENT == *"{{dp"* ]] || [[ $CONTENT == *"{{Dp"* ]]; then
					echo "This is a disambiguation page"
					continue
				fi
				
				if [[ $CONTENT == *"{{nuweg"* ]] || [[ $CONTENT == *"{{speedy"* ]] || [[ $CONTENT == *"{{delete"* ]]; then
					echo "Has been nominated for speedy deletion"
					continue
				fi
				
				if [[ $CONTENT == *"{{meebezig"* ]] || [[ $CONTENT == *"{{Meebezig"* ]]; then
					echo "Is being worked on"
					continue
				fi
				
				if [[ $CONTENT == *"#doorverwijzing"* ]] || [[ $CONTENT == *"#DOORVERWIJZING"* ]]; then
					echo "Is a redirect page"
					continue
				fi
				
				if [[ $CONTENT == *"#redirect"* ]] || [[ $CONTENT == *"#REDIRECT"* ]]; then
					echo "Is a redirect page (2)"
					continue
				fi
				
				echo "Editing ${article}"
				
				CR=$(curl -S \
					--location \
					--cookie $cookie_jar \
					--cookie-jar $cookie_jar \
					--user-agent "nocat.sh by Smile4ever" \
					--keepalive-time 60 \
					--header "Accept-Language: en-us" \
					--header "Connection: keep-alive" \
					--compressed \
					--data-urlencode "title=${article}" \
					--data-urlencode "nocreate=true" \
					--data-urlencode "summary=+${NOCAT}" \
					--data-urlencode "appendtext=${NOCAT}" \
					--data-urlencode "token=${EDITTOKEN}" \
					--request "POST" "${WIKIAPI}?action=edit&format=json")
				
				ERRORINFO=$(echo $CR | jq '.error.info' 2>/dev/null)
				if [[ $ERRORINFO == *"The page you specified doesn't exist."* ]]; then
					echo "Skipping ${article}"
				else
					echo "$CR" | jq .
					echo $articleClean >> $PAGES
					echo "Waiting 60 seconds"
					sleep 60
				fi 
				
				#TODO: add check
				
			else
				echo $articleClean >> $PAGES
				echo "I would edit ${article}"
			fi
		fi
		
		#Show the categories without the first line, which is the article's title
		#tail -n +2 $CURRENTCATSTXT
		
		echo "------------------"
	#	sizediff=$(stat -c%s diff.txt)
		
	done

	#rm $RECENTCHANGES
	#rm $RECENTCHANGESTXT
	#rm $CURRENTCATS
	#rm $CURRENTCATSTXT

	
	EDITEDPAGES=$(cat $PAGES 2>/dev/null)
	if [[ $EDITEDPAGES == "" ]]; then
		echo "I've edited no pages."
	else
		echo "I've edited these pages:"
		echo $EDITEDPAGES
	fi
	
	if [[ -e $LISTEDITEDPAGES ]]; then
		echo ""
		echo "Edit history"
		tac $LISTEDITEDPAGES | head -n10 
	fi
	
	if [[ $EDITEDPAGES != "" ]]; then
		echo $EDITEDPAGES >> $LISTEDITEDPAGES
	fi
	
	#Delete all files in directory, leave subdirs as is
	#for f in $(ls | grep -v .sh | grep -v .md  | grep -v .config | grep -v password | grep -v list); do [[ -d "$f" ]] || rm "$f"; done
	rm -rf data
	
	CURDATE=$(date +"%T")
	echo "${CURDATE} Waiting 5 minutes.."
    sleep 300
done

