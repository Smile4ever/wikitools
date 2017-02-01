nocat.sh
========
Add the {{nocat}} template to new pages which don't have any categories.

Requirements
============
Software:
* wget and curl (yes, both)
* jq
* openssl

Info:
* valid username and password for wiki
* read and write rights in the script directory

How to use
============
Make sure you have configured WIKIAPI at the top of the file:

    WIKIAPI="https://nl.wikipedia.org/w/api.php"

Also, EDIT needs to be set to true, otherwise the script won't edit pages

    EDIT="true"

After the steps above, just execute the script:

    ./nocat.sh
    
By default, the script will ask for a username and a password when running for the first time. It will remember these settings because they are stored in the /config subdirectory.

The /data directory contains all temporary files when the script is executing. You can safely delete this subdirectory when the script has finished or terminated unexpectedly.

The list-editedpages.txt keeps the history of the edits nocat.sh has made. It is advised you do not delete this file. The file is created if it does not exist after the first edit has been made.
