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
# ####################################################################


# find and delete files older than 30 days
find /tmp/ -mtime +30 -delete
find /mnt/scratch -mtime +30 -delete

# clean-up old jobs...
outfile=/tmp/dirlist.out
if [ -e $outfile ]; then
        rm $outfile
fi
# find all webserver job directories older than 60 day and save them to file,
# we will then use the list to delete them
find /var/www/ -type d -mtime +60 | egrep [u][0-9]\{4}[a-zA-Z0-9]\{5} > $outfile

if [ -e $outfile ]; then
        logfile=/tmp/cleanup.log
        if [ -e $logfile ]; then
                rm $logfile
        fi
        while read l; do
                echo "deleting job directory ${l} [last modified $(stat -c %y "${l}")]" >>  $logfile
                rm -rf "${l}"
                echo -e "----\n"
        done <$outfile
fi
