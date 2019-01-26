category_stats
--------------
category_stats is a script to (constantly) check a MediaWiki category. It uses the MediaWiki API. The  script saves the members of a category at certain intervals for analysis / statistics.

Requirements
------------
* wget
* jq

Usage
------
Check every hour and save data in /data/run:
  DATADIRECTORY=/data/run SLEEPDURATION=3600 ./category_stats.sh

Notes
-----
* If you use this script with large categories, please do not use this script with too small timeouts. This has two reasons:
  * It takes a while to fetch the category members. Running the script again when it is not finished will not get you the desired results.
  * To prevent unnecessary load on the MediaWiki API of the site you are using.
