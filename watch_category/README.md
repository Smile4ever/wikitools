watch_category
--------------
watch_category is a script to (constantly) check a MediaWiki category. It uses the MediaWiki API. Once it detects changes in the category members, it opens the changed pages or the category page in the default browser (see Configuration).

This script also is a bot for an IRC channel.

Requirements
------------
* wget
* jq
* xdg-open
* notify-send (libnotify)
* ii ([link](http://tools.suckless.org/ii))

Usage
------
Automatically:
1) check every minute (configured in-script)
2) the category page (configured in-script)
3) joining IRC channel #wikipedia-nl-vandalism on freenode
4) with username smilebot-nuweg:

  BOTNAME=smilebot-nuweg CHANNEL=#wikipedia-nl-vandalism ./watch_category.sh

Quit bot:
1) press CTRL+C
2) run ./quitbot.sh (this is strongly advised in order to have a clean shutdown)

Configuration
----------------------

You will probably need to set parameters. This is done like this:

  BOTNAME=mybot CHANNEL=#example NETWORK=irc.freenode.net ./watch_category.sh

These are the default values:

General:
* CATEGORY="Categorie:Wikipedia:Nuweg"
* PROTOCOL="https://"
* WIKI="nl.wikipedia.org"
* OPENPAGES="true" (set to false if you want to open the category page instead of individual pages)

IRC:
* BOTNAME="smilebot-watchcat"
* NETWORK="irc.freenode.net"
* CHANNEL="#wikipedia-nl-vandalism"
* INFOMESSAGES="false" (do not display infomessages in the IRC channel)
* SPEAKLANG="en" (can also be set to "nl", has no effect on infomessages currently)

Tips
----
* For nl.wikipedia.org, this script can be combined with [Fast Delete](https://addons.mozilla.org/en-US/addon/fast-delete/) (for example, checking the category Categorie:Wikipedia:Nuweg)
* Always use ./quitbot.sh after exiting ./watch_category.sh.

Notes
-----
* The script is limited to the first 500 members of a category.
* Please do not use this script with too small timeouts, e.g. < 15 seconds. This has two reasons:
** It takes a while to fetch the page. Running the script again when it is not finished will not get you the desired results.
** To prevent unnecessary load on the MediaWiki API of the site you are using.
