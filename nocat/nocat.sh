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
	
	echo "Checking RCSTART"
	RCSTART=$(date -d '3 hours ago' "+%Y-%m-%dT%H:%M:%S.000Z")
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
			echo "Getting a login token failed. Retrying..."
			sleep 5
			continue
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
	RECENTLOGS="data/recentlogs.json"
	RECENTNOCAT="data/recentnocat.json"
	ALLPAGES="data/recentchanges.txt"

	CURRENTCATS="data/current-categories.json"
	CURRENTCATSTXT="data/current-categories.txt"
	PAGES="list-pages.txt"
	LISTEDITEDPAGES="list-editedpages.txt"

	rm $PAGES 2>/dev/null
	
	echo "Fetching page data"

	wget "https://nl.wikipedia.org/w/api.php?action=query&list=recentchanges&rcprop=title|user&rcnamespace=0&rctype=new&rclimit=50&rcshow=!redirect&format=json&rcstart=${RCSTART}" -T 60 -O $RECENTCHANGES >/dev/null 2>&1
	jq -r ".query.recentchanges[] | .title" $RECENTCHANGES > $ALLPAGES
	wget "https://nl.wikipedia.org/w/api.php?action=query&list=logevents&letype=move&lelimit=50&format=json" -T 60 -O $RECENTLOGS >/dev/null 2>&1
	jq -r ".query.logevents[] | .title" $RECENTLOGS | grep -v ":" >> $ALLPAGES
	wget "https://nl.wikipedia.org/w/api.php?action=query&list=querypage&qppage=Uncategorizedpages&format=json" -T 60 -O $RECENTNOCAT >/dev/null 2>&1
	jq -r ".query.querypage.results[] | .title" $RECENTNOCAT | grep -v ":" >> $ALLPAGES
	
	IFS=$'\n'
	for article in $(cat $ALLPAGES | tr -d '\r')    
	do
		articleClean=$article
		#echo "Processing $article"
		article="${article// /_}"
		#article="${article//\r/}"
		
		wget "https://nl.wikipedia.org/w/api.php?action=query&titles=$article&prop=categories&format=json&clshow=!hidden" -T 60 -O $CURRENTCATS >/dev/null 2>&1
	
		#cat $CURRENTCATS
		#echo ""

		#Key parsen met jq:
		jq -r '.query.pages | .. | .title? | select(.)' $CURRENTCATS > $CURRENTCATSTXT
		COUNTVISIBLE=$(cat $CURRENTCATSTXT | grep -v ":Wikipedia:" | wc -l)
		COUNTVISIBLE=$(expr $COUNTVISIBLE - 1)
		COUNTHIDDEN=$(cat $CURRENTCATSTXT | grep ":Wikipedia:" | wc -l)
		COUNTALL=$(expr $COUNTVISIBLE + $COUNTHIDDEN)
		echo $COUNTALL categories, including $COUNTHIDDEN hidden categories on $articleClean
		
		# Talkpage edits
		echo "Fetching talkpage edits"
		wget "https://nl.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&continue=%7C%7C&titles=Overleg+gebruiker%3A${USERNAME}&converttitles=1&rvprop=timestamp&rvlimit=1" -T 60 -O data/date.json >/dev/null 2>&1
	
		TODATE=$(date -d '150 minutes ago' "+%s")
		COND=$(grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' data/date.json)
		CONDUNIX=$(date -d "$COND" '+%s')
		
		if [ $CONDUNIX -gt $TODATE ]; then
			echo "Bot has stopped, because its talkpage has been edited in the last 30 minutes."
			rm -rf data
			exit
		fi 
		
		if [[ $COUNTVISIBLE -eq 0 ]]; then	
			if [[ $EDIT == "true" ]]; then
				echo "Fetching CURL"
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
				CONTENT=$(echo "$CR"|jq -r '.query.pages')
				
				#Checks the content of the page and doesn't place a {{nocat}} template if one of these strings are in the json
				if [[ $CONTENT == *'missing":'* ]]; then
					echo "Malformed/deleted article"
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
				
				if [[ $CONTENT == *"Categorie:Wikipedia:Doorverwijspagina"* ]]; then
					echo "Has already the category Categorie:Wikipedia:Doorverwijspagina"
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
				
				if [[ $CONTENT == *"{{meebezig"* ]] || [[ $CONTENT == *"{{Meebezig"* ]] || [[ $CONTENT == *"{{Wiu2"* ]] || [[ $CONTENT == *"{{wiu2"* ]]; then
					echo "Is being worked on"
					continue
				fi
				
				if [[ $CONTENT == *"#doorverwijzing"* ]] || [[ $CONTENT == *"#DOORVERWIJZING"* ]] || [[ $CONTENT == *"#Doorverwijzing"* ]] || [[ $CONTENT == *"#redirect"* ]] || [[ $CONTENT == *"#REDIRECT"* ]] || [[ $CONTENT == *"#Redirect"* ]]; then
					echo "Is a redirect page"
					continue
				fi
				
				CRCHECK=$(curl -S \
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

				CONTENTCHECK=$(echo "$CRCHECK"|jq -r '.query.pages')
				
				if [[ $CONTENTCHECK == *"#doorverwijzing"* ]] || [[ $CONTENTCHECK == *"#DOORVERWIJZING"* ]] || [[ $CONTENTCHECK == *"#Doorverwijzing"* ]] || [[ $CONTENTCHECK == *"#redirect"* ]] || [[ $CONTENTCHECK == *"#REDIRECT"* ]] || [[ $CONTENTCHECK == *"#Redirect"* ]]; then
					echo "Is a redirect page, 2nd check"
					continue
				fi
				
				if [[ $CONTENTCHECK == *"{{dp"* ]] || [[ $CONTENTCHECK == *"{{Dp"* ]]; then
					echo "This is a disambiguation page, 2nd check"
					continue
				fi
				
				echo "Editing ${article}"

				echo "Adding {{nocat}} template"
				
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
					echo "Waiting 5 seconds"
					sleep 5
				fi 
				
			else
				echo $articleClean >> $PAGES
				echo "I would edit ${article}"
			fi
		fi
		
		#Show the categories without the first line, which is the article's title
		#tail -n +2 $CURRENTCATSTXT

	#	sizediff=$(stat -c%s diff.txt)
		
	done

	#rm $RECENTCHANGES
	#rm $ALLPAGES
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
	echo "${CURDATE} Waiting 15 minutes.."
    sleep 900
done
