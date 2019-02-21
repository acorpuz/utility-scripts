#!/bin/bash
#
# clean_temp_dirs.sh
#
# ####################################################################
# Description:  General clean-up script. Deletes files older than 30 
#               days from specified dirs and deletes webserver job
#               directories older than 60 days.
#				Script is added to crontab and run every sunday
#				[* * * * 0 /bin/sh /root/Scripts/clean_temp_dirs.sh]
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 21.06.2016 14:34:35 CEST
# ======== Changelog ========
# 2016-06-21 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Initial script
#
# 2016-06-30  bioadmin  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added find for job directories older than 60 days
#
# 2016-07-05  bioadmin  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added delete loop reading input from file
# * Cleaned-up script and added comments
#
# 2016-07-07  bioadmin  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Activated script
#
# 2016-08-02  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Modifided script to change to targer directoory before finding and/or
#	deleting files.
# 2017-01-26  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Clean up script, minor formatting, delete used files. permission on files 
#
# ####################################################################

outfile=/tmp/dirlist.out
logfile=/tmp/cleanup.log
days_to_keep_jobs=60

# check for root
if [ "$EUID" -ne 0 ]; then
	echo "Run scripts as root."
	exit 1
fi

# find and delete files older than 30 days in temp dirs
for i in "/tmp" "/mnt/scratch" "/var/tmp"; do
	find "$i" -mtime +30 -delete
done

# clean-up old jobs and logs...
for i in "$outfile" "$logfile"; do
	if [ -e "$i" ]; then
		rm -f "$i"
	fi
	touch "$outfile"
	chmod 600 "$outfile"
done

# Find all webserver job directories older than 60 day and save them to file,
# we will then use the list to delete them.
# The pattern is not valid for all webservers.
# TODO: expand to include other job patterns for other webservers ...
 
cd /var/www/ || exit
find . -type d -mtime +${days_to_keep_jobs} | grep -E "[u][0-9]\{4}[a-zA-Z0-9]\{5}" > $outfile

while read -r l; do
	if [ -e "$l" ]; then
		echo "Deleting job directory ${l} [last modified $(stat -c %y "${l}")]" >>  "$logfile"
		rm -rf "$l"
		echo -e "----\n"
	fi
done <"$outfile"

exit 0
