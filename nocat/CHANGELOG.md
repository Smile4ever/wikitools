CHANGELOG
==

20200905
====
* Initial support for login-throttled (needs more work not to get stuck on retry)
* Max login tries increased to 10
* Retrying to login with more information
* Cleanup/clarify code

20200904
====
* Fix URL encoding issue while retrieving categories by using cURL instead of wget
* Fix issue with retrieving categories; no categories retrieved now means we continue with a warning
* Color coding and output optimized
* Replace hardcoded URL in some places by the WIKIAPI variable
* Logging is available; use nocat.sh | tee -a nocat.log
* Keep edittoken.json for auditing purposes to investigate issues
* Fix variable interpolation for edittoken logging
* Fix issue with edit history; newlines are back again

20200420
====
* Use --data-urlencode for editing the page
* Set max-time and connect-timeout for do_login

20200225
====
* Improve logging
* Retry login, fixes #1
* Only fetch talk page edits before editing, not yet when querying (saves a lot of requests)
* Fix bug introduced in f443574#diff-bdfe145de19c792462ee8ad7c9a15455
which is seen at
https://nl.wikipedia.org/w/index.php?title=Birgittijnenklooster_(Borgloon)&diff=49963453&oldid=49958639
and
https://nl.wikipedia.org/w/index.php?title=Hoogeveense_Cascaderun&type=revision&diff=55529515&oldid=55528710

20190423
====
* Include results from Special page Uncategorizedpages

20170510
====
* Add extra check for Categorie:Wikipedia:Doorverwijspagina

20170504
====
* Temporary fix for a problem

20170405
====
* Update nocat.sh

20170404
====
* Cleanup and bug fixes

20170312
====
* Fix CONTENTLENGTH count

20170311
====
* Skipping page with CONTENTLENGTH 0 or 1

Older
====
See git: https://github.com/Smile4ever/wikitools/commits/master
