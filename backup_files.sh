#!/bin/bash
#
# Script name: backup_files.sh
#
# ####################################################################
# Description: quick script to backup files. Renames the original file 
#	using the pattern <filename>_<date>.bck to preserve timestamps
#	and then copies it in archive (-a option) mode renaming it
#	to the original name.
# Parameters: needs filename/dirname to backup.
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 19.05.2016 10:55:40 CEST
# ======== Changelog ========
# 2016-05-19 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * initial script
#
#
#
# ####################################################################


showuse () {
	echo -e "Pass an existing filename to the script\n" 
	echo -e "\tFile will be backed-up with the current" 
	echo -e "\ttimestamp and the extension \".bck\" in its name." 
}

checkparam () {

	# We need one parameter, check for it...
	if [ ! $# -eq 1 ]; then
		showuse
		exit 1
	fi

	# the file must exist
	local file_name="$1"
	if [ ! -e "$file_name" ]; then
		echo "File ${file_name} not found."
		exit 1		
    fi  
}


checkparam "$@"
filename="$1"

# Check if user can access the file
if [ -r "$filename" ]; then
	
	curr_dir=$(dirname "${filename}")
	# check if user can write to current directory
	if [ ! -w "$curr_dir" ]; then
		echo "No write permissions in ${curr_dir}."
		exit 1
	fi
	
	curr_date=$(date +%F_%H.%M.%S)
	bckupfilename=${filename}-${curr_date}.bck
	
	mv "$filename" "$bckupfilename"
	cp -a "$bckupfilename" "$filename"
	
	exit 0
else
	echo "Run as root."
	exit 1
fi
