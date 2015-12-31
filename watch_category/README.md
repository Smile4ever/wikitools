watch_category
--------------
watch_category is a script to (constantly) check a MediaWiki category. It uses the MediaWiki API. Once it detects changes in the category members, it opens the changed pages or the category page in the default browser (see Configuration).

Requirements
------------
* wget
* jq
* xdg-open
* notify-send (libnotify)

Usage
------
Automatically check every minute the category page configured in the script:
  watch -n60 ./watch_category.sh

Automatically check every minute, using the command line parameter --cat:
  watch -n60 ./watch_category.sh --cat Category:Wikipedia

Configuration
----------------------

At the top of the script, you can set a few parameters. A runtime switch (like --cat) override the corresponding parameter.

* CATEGORY="Categorie:Wikipedia:Nuweg"
* PROTOCOL="https://"
* WIKI="nl.wikipedia.org"

Optional:

* OPENPAGES="true" (set to false if you want to open the category page)

Tips
----
* For nl.wikipedia.org, this script can be combined with [Fast Delete](https://addons.mozilla.org/en-US/addon/fast-delete/) (for example, checking the category Categorie:Wikipedia:Nuweg)

Notes
-----
* The script is limited to the first 500 members of a category.
* Please do not use this script with too small timeouts, e.g. < 15 seconds. This has two reasons:
** It takes a while to fetch the page. Running the script again when it is not finished will not get you the desired results.
** To prevent unnecessary load on the MediaWiki API of the site you are using.
