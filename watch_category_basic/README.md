watch_category
--------------
watch_category is a script to (constantly) check a MediaWiki category. It uses the MediaWiki API. Once it detects changes in the category members, it opens the changed pages or the category page in the default browser (see the top of the script).

Requirements
------------
* wget
* jq
* xdg-open (optional, needed for bot)
* notify-send (libnotify) (optional)
* watch
* xdotool (needed for bot)

Usage
------
Check every 20 seconds:
  watch -n20 ./watch_category.sh

Tip: automatically delete pages from a category (nl.wikipedia.org)
----
For nl.wikipedia.org, this script can be combined with [Fast Delete](https://addons.mozilla.org/en-US/addon/fast-delete/).

To set this up:
* install Firefox (or any derived browser, such as Seamonkey or Pale Moon)
* install Fast Delete in Firefox and check the option Safe mode in the preferences
* start the bot script: watch -n5 ./send-f8.sh
* start the watch script: watch -n5 ./watch_category.sh

Please note that you will need to dedicate a machine for this, as your computer will constantly open (and close) new tabs. This software can run on the Raspberry Pi.

Notes
-----
* The script is limited to the first 500 members of a category.
* Please do not use this script with too small timeouts, e.g. < 2 seconds. This has two reasons:
⋅⋅* It takes a while to fetch the page. Running the script again when it is not finished will not get you the desired results.
⋅⋅* To prevent unnecessary load on the MediaWiki API of the site you are using.
