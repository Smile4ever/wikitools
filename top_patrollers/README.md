Top patrollers
----------

top_patrollers is a script to generate a list of users including the total patrolled (edits) count on a MediaWiki website, using the MediaWiki API. The generated data can be further processed with jq if desired.

Data that has previously been generated can be found here: ftp://itsafeature.org/top_patrollers

Requirements
------------
* wget
* jq
* uniq
* sort
* ruby
* truncate
* head
* sed

For big wikis, a 64 bit computer and up to 16 gigabytes of free RAM is recommended. Having multiple gigabytes of free disk space is required.

Usage
------
Create the list:
  ./top_patrollers.sh
 
This will create the list for nl.wikipedia.org. Depending on your internet connection and amount of patrolled edits, this can take from a few hours to multiple days. The list will be saved as "apiresult.json" and "apiresult-small.json".

While running the script, it will display its progress by showing the next patrol timestamp (+499) that will be retrieved.

Configuration
----------------------

You can specify which wiki to generate the list for:
  PROTOCOL="https://" WIKI="en.wikipedia.org" ./top_patrollers.sh

These are the default values:

* PROTOCOL="https://"
* WIKI="nl.wikipedia.org"

Output
------
Example output (filtered-summary-patrol-wikitext.txt):

	# {{intern|1=title=Gebruiker:Goudsbloem|2=Goudsbloem}} (markeringen: 502567)
	# {{intern|1=title=Gebruiker:Maniago|2=Maniago}} (markeringen: 334759)
	# {{intern|1=title=Gebruiker:Look_Sharp!|2=Look Sharp!}} (markeringen: 302700)
	# {{intern|1=title=Gebruiker:Capaccio|2=Capaccio}} (markeringen: 292348)
	# {{intern|1=title=Gebruiker:Ronn|2=Ronn}} (markeringen: 290130)
	# {{intern|1=title=Gebruiker:MatthijsWiki|2=MatthijsWiki}} (markeringen: 232552)
	# {{intern|1=title=Gebruiker:Richardkiwi|2=Richardkiwi}} (markeringen: 216946)
	# {{intern|1=title=Gebruiker:Edoderoo|2=Edoderoo}} (markeringen: 199147)
	# {{intern|1=title=Gebruiker:MrBlueSky|2=MrBlueSky}} (markeringen: 172974)
	# {{intern|1=title=Gebruiker:ARVER|2=ARVER}} (markeringen: 142974)

If you want plain JSON, you can look at the file filtered-summary-patrol.json, formatted as follows:

	[
		{
			"column1": "1",
			"column2": "502567",
			"column3": "Goudsbloem"
		},
		{
			"column1": "2",
			"column2": "334759",
			"column3": "Maniago"
		}
	]

If you need to have more information, look at apiresult.json or apiresult-small.json.
