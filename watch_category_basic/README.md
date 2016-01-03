watch_category
--------------
watch_category is a script to (constantly) check a MediaWiki category. It uses the MediaWiki API. Once it detects changes in the category members, it opens the changed pages or the category page in the default browser (see the top of the script).

Requirements
------------
* wget
* jq
* xdg-open
* notify-send (libnotify)
* watch

Usage
------
Check every 20 seconds:
  watch -n20 ./watch_category.sh

Tips
----
* For nl.wikipedia.org, this script can be combined with [Fast Delete](https://addons.mozilla.org/en-US/addon/fast-delete/) (for example, checking the category Categorie:Wikipedia:Nuweg)

Notes
-----
* The script is limited to the first 500 members of a category.
* Please do not use this script with too small timeouts, e.g. < 15 seconds. This has two reasons:
** It takes a while to fetch the page. Running the script again when it is not finished will not get you the desired results.
** To prevent unnecessary load on the MediaWiki API of the site you are using.
