watch_category
--------------
watch_category is a bot script to (constantly) check a MediaWiki category. It uses the MediaWiki API. Once it detects changes in the category members, it signals this on an IRC channel. It also opens the changed pages or the category page in the default browser (see Configuration) unless DESKTOPINT is set to false.

Requirements
------------
* wget
* jq
* xdg-open (optional)
* notify-send (libnotify, optional)
* ii ([link](http://tools.suckless.org/ii), optional)

Usage
------
Automatically:
1. check every minute (configured in-script)
2. the category page (configured in-script)
3. joining IRC channel #wikipedia-nl-vandalism on freenode
4. with username smilebot-nuweg
5. only the IRC module (disabling desktop integration):

  BOTNAME=smilebot-nuweg CHANNEL=#wikipedia-nl-vandalism DESKTOPINT=false ./watch_category.sh

Quit bot:
1) press CTRL+C
2) run ./quitbot.sh (this is strongly advised in order to have a clean shutdown)

Restart bot:
1) press CTRL+C
2) run ./watch-category.sh again

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
* IRCENABLED="true": enables IRC integration
* DESKTOPINT="true": set this to false if you want to run the bot on a (headless) server. disables libnotify and xdg-open integration

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
