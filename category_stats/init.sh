#!/bin/bash
echo "Cleaning up"
rm api.php*
rm list.txt
rm prev.txt
rm diff-new.txt 2>/dev/null
rm diff-gone.txt 2>/dev/null
touch list.txt
