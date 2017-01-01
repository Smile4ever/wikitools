#!/bin/bash
echo "Cleaning up"
rm api.php*
rm result.txt 2>/dev/null
rm prev.txt
rm diff.txt 2>/dev/null
touch result.txt
