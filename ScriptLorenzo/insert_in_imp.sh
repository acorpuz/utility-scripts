#!/bin/bash

# File name: insert_in_imp.sh 
# ############################################################################
# Description:  Insert text from in-file between 'CONFIG' and 'CLOSECONFIG'
#				tags in out-file.
#
#
# ToDo: check il files exist
# ToDo: check il tags exist in out file, get linenumbers
# ToDo: read content of in-file
# ToDo: backup out-file
# ToDo: substitute text in outfile
#
# ----------------------------------------------------------------------------
# Sapienza Biocomputing Group
# Created on 2019-06-11
# ############################################################################

. /lib/lsb/init-functions

DEL_BACKUP=0
START_TAG="CONFIG"
END_TAG="CLOSECONFIG"

show_usage(){
	echo ""
	echo "Uso: $(basename "$0") -i in-file -o out-file"
	echo "Opzioni:"
	echo "  -i|--in-file		file from which the text to be inserted is read"
	echo "  -o|--out-file		destination file where text will be inserted between"
	echo "  					the lines 'CONFIG' and 'CLOSECONFIG'"
	echo "  -x|--delete-backup	delete backup of out-file when done"
	echo "  -h|--help			show this help and exit"
	echo " "
	exit 0
}


parse_options(){
	args=$(getopt -o hi:o:x -n $0 -- "$@")
	eval set -- "$args"

	for i in "$@"
	do
		case "$1" in
			-i|--in-file)
				IN_FILE="$2";;
			-o|--out-file)
				OUT_FILE="$2";;
            -x|--delete-backup)
				DEL_BACKUP=1;;
            -h|--help)
				show_usage;;
			*)
				# unrecognized option, do nothing.
				;;
		esac
		shift 2
	done
}

if [ "$#" -eq 0 ]; then
	show_usage
	exit 0
else
	parse_options "$@"

	log_action_begin_msg "Checking files"

	log_action_cont_msg "Check if in-file ${IN_FILE} exists"
 	if [ ! -f "$IN_FILE" ]; then
 		log_failure_msg "Missing file ${IN_FILE}"
 		exit 0
	fi

	log_action_cont_msg "Check if out-file ${OUT_FILE} exists"
	if [ ! -f "$OUT_FILE" ]; then
 		log_failure_msg "Missing file ${IN_FILE}"
 		exit 0
	fi
	log_action_cont_msg "Find tags in out-file ${OUT_FILE}"
	if grep -q "$START_TAG" "$OUT_FILE" ; then
		start_line=$(grep -F -n -m 1 "$START_TAG" "$OUT_FILE" | awk -F: '{ print $1 }')
		log_action_cont_msg "Found ${START_TAG} tag in out-file ${OUT_FILE} at line ${start_line}"
		# skip line after TAG
		start_line=$(( start_line + 2 ))
	else
		log_failure_msg "Tag ${START_TAG} not found in ${IN_FILE}"
 		exit 10
	fi
	if grep -q "$END_TAG" "$OUT_FILE" ; then
		end_line=$(grep -F -n -m 1 "$END_TAG" "$OUT_FILE" | awk -F: '{ print $1 }')
		log_action_cont_msg "Found ${END_TAG} tag in out-file ${OUT_FILE} at line ${end_line}"
		# Stop before actual line
		end_line=$(( end_line -1 ))
	else
		log_failure_msg "Tag ${END_TAG} not found in ${IN_FILE}"
 		exit 10
	fi
    # all done, report outcome
    log_action_end_msg 0
    log_success_msg "Files OK, substituting between lines ${start_line} and ${end_line}"

	log_action_begin_msg "Deleting lines ${start_line} - ${end_line}"
	sed -i.bck "${start_line},${end_line}d" "$OUT_FILE"
	log_action_begin_msg "Inserting lines from file ${IN_FILE}"
	# sed append so we start from 1 line up
	start_line=$(( start_line - 1 ))
	sed -i "${start_line}r ${IN_FILE}" "$OUT_FILE"
    log_success_msg "File updated"
    log_action_end_msg 0


	if [ $DEL_BACKUP -eq 1 ]; then
		bckup_file="${OUT_FILE}.bck"
		log_action_msg "Removing backup ${bckup_file}"
		rm "$bckup_file"
	fi
fi