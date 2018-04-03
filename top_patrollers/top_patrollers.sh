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

LENGTH=500

LECONTINUE="&lecontinue=20170320175242|26847504" #debugging
LECONTINUE=""

echo "[" > apiresult.json
echo "[" > apiresult-small.json

while [[ $LENGTH -eq 500 ]]
do
	rm api.php* 2>/dev/null
	wget --user-agent="usersbyedits tool by Smile4ever" "$PROTOCOL$WIKI/w/api.php?action=query&list=logevents&letype=patrol&lelimit=500&format=json$LECONTINUE&ledir=newer" 2&>/dev/null
	LECONTINUE=`jq -r '.continue.lecontinue' api.php*`
	echo $LECONTINUE
	LECONTINUE="&lecontinue=$LECONTINUE"

	jq -r '.query.logevents[]' api.php* | sed "s/}/},/" >> apiresult.json
	jq -r '.query.logevents[] | {user: .user, action: .action}' api.php* | sed "s/}/},/" >> apiresult-small.json
	
	jq -r '.query.logevents[] | select(.params.auto == "") | .user' api.php* >> result-autopatrol.txt
	jq -r '.query.logevents[] | select(.params.auto != "") | .user' api.php* >> result-patrol.txt
	jq -r '.query.logevents[] | .user' api.php* >> result-autopatrol-patrol.txt
	
	LENGTH=`jq -r '.query.logevents | length' api.php*`
	if [[ $LENGTH != "500" ]]; then
		truncate -s-2 apiresult.json
		truncate -s-2 apiresult-small.json
		echo "Finishing the JSON files.."
	fi
done

echo "]" >> apiresult.json
echo -e "\n]" >> apiresult-small.json

###########################################################################################################################################
echo "Filtering bots"
cp result-patrol.txt filtered-list-patrol.txt
cp result-autopatrol.txt filtered-list-autopatrol.txt
cp result-autopatrol-patrol.txt filtered-list-autopatrol-patrol.txt

###########################################################################################################################################
echo "Making JSON files"
echo "filtered-summary-patrol.txt"
sort filtered-list-patrol.txt | uniq -c | sort -nr | sed -r 's/([0-9]) /\1\t/' | cat -n > filtered-summary-patrol.txt
head -n100 filtered-summary-patrol.txt
cat filtered-summary-patrol.txt | ./convert_to_json > filtered-summary-patrol.json

echo "filtered-summary-autopatrol.txt"
sort filtered-list-autopatrol.txt | uniq -c | sort -nr | sed -r 's/([0-9]) /\1\t/' | cat -n > filtered-summary-autopatrol.txt
head -n100 filtered-summary-autopatrol.txt
cat filtered-summary-autopatrol.txt | ./convert_to_json > filtered-summary-autopatrol.json

echo "filtered-summary-autopatrol-patrol.txt"
sort filtered-list-autopatrol-patrol.txt | uniq -c | sort -nr | sed -r 's/([0-9]) /\1\t/' | cat -n > filtered-summary-autopatrol-patrol.txt
head -n100 filtered-summary-autopatrol-patrol.txt
cat filtered-summary-autopatrol-patrol.txt | ./convert_to_json > filtered-summary-autopatrol-patrol.json

echo "Done, saved as filtered-list-*.txt / apiresult*.json"

###########################################################################################################################################
echo "Creating wikitext files"

FILEINPUT="filtered-summary-patrol.json"
FILE="filtered-summary-patrol-wikitext.txt"
jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.column3 | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .column3, "}} (markeringen: ", .column2, ")", "\t" ] | join("\t")' $FILEINPUT | cat > $FILE
sed -i 's/\t//g' $FILE

FILEINPUT="filtered-summary-autopatrol.json"
FILE="filtered-summary-autopatrol-wikitext.txt"
jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.column3 | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .column3, "}} (markeringen: ", .column2, ")", "\t" ] | join("\t")' $FILEINPUT | cat > $FILE
sed -i 's/\t//g' $FILE

FILEINPUT="filtered-summary-autopatrol-patrol.json"
FILE="filtered-summary-autopatrol-patrol-wikitext.txt"
jq -r '.[] | [ "# {{intern|1=title=Gebruiker:", (.column3 | sub(" "; "_") | sub(" "; "_") | sub(" "; "_")), "|2=", .column3, "}} (markeringen: ", .column2, ")", "\t" ] | join("\t")' $FILEINPUT | cat > $FILE
sed -i 's/\t//g' $FILE
###########################################################################################################################################

# Cleanup
rm api.php* 2>/dev/null
rm result*.txt 2>/dev/null
