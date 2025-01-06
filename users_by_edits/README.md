Users by edits
----------

users_by_edits is a script to generate a list of users including user count on a MediaWiki website, using the MediaWiki API. Sorting and filtering of bot accounts is done automatically.

The generated data can be further processed with jq if desired.

Time is in UTC.

Requirements
------------
* curl
* jq
* uniq
* parallel (recommended)

For big wikis, a computer with at least 8 gigabytes of free RAM is recommended.

Operating systems:
* Linux supported
* macOS not tested
* Windows Subsystem for Linux (WSL) works

Usage
------
Create the list:
  ./users_by_edits.sh
 
This will create the list for nl.wikipedia.org. Depending on your internet connection and the number of users on the wiki, this can take from a few minutes to several hours. The list will be saved as "usernames-all.tsv".

While running the script, it will display its progress by showing the next user (+499) that will be retrieved.

After that, it will retrieve first edit datetime, last edit datetime and whether the user is a bot (in the past or currently).

Configuration
-------------

You can specify which wiki to generate the list for:
  WIKI="https://en.wikipedia.org" ./users_by_edits.sh

To use your correct locale, specify $I18N_EDITS and $I18N_USER:
  WIKI="https://en.wikipedia.org" I18N_EDITS="edits" $I18N_USER="User" ./users_by_edits.sh

These are the default values:

* WIKI="https://nl.wikipedia.org"
* I18N_EDITS="bewerkingen"
* I18N_USER="Gebruiker"

Specifics
---------
* To increase performance, only users with at least 100 edits are processed
* The function calculateIsBot does some tricks to see which accounts are bots. It's not perfect, so some users have overrides.

Output
------
Example output (usernames-all.tsv):

	Aadekker59	1
	Aadelij	5
	Aadelse	3
	Aadjanson	43
	Aadjanson~enwiki	1
	Aadje	20
	Aadje2	1
	Aadje93	2
	Aadjuh	6

If you want plain JSON, you can look at the file sorted-data.json, formatted as follows:

	[{
	  "name": "!-!--:annekelol:--!-!",
	  "editcount": 1
	},
	{
	  "name": "!Jeroen!",
	  "editcount": 4
	}]

If you need to have the information about edit dates as well, look at expanded-sorted-data.json.
    
The output is also processed to a wikitext list. See the files with "wikitext" in the name for that. It is similar to this:

    # {{intern|1=title=Gebruiker:MoiraMoira|2=MoiraMoira}} (bewerkingen: 488447)
    # {{intern|1=title=Gebruiker:ErikvanB|2=ErikvanB}} (bewerkingen: 390474)
    # {{intern|1=title=Gebruiker:Romaine|2=Romaine}} (bewerkingen: 358678)
    # {{intern|1=title=Gebruiker:RonaldB|2=RonaldB}} (bewerkingen: 315097)
    # {{intern|1=title=Gebruiker:Rudolphous|2=Rudolphous}} (bewerkingen: 208952)
    # {{intern|1=title=Gebruiker:Michiel1972|2=Michiel1972}} (bewerkingen: 195575)
