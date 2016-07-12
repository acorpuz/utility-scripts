#!/bin/bash
#
# disable_user.sh
#
# ####################################################################
# Description: 	Disable users that haven't logged in in 1+ year
# 				Also tar home directory and remove uncompressed dir.
#
#
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 12.07.2016 11:04:54 CEST
# ======== Changelog ========
# 2016-01-12 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Initial script
#
# 2016-07-12  bioadmin  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Clean-up script, add comments, made as function so you can pass 
#   the username you want disabled to script. Added more control functions
#   (check_user, check_login, read_home) 
#
# ####################################################################

function check_user {
	# Check if user exists on system; returns 0 if exists, 1 if non exists
	# Needs username as only parameter
	local USR
	USR="$1"
	getent passwd "$USR"  > /dev/null
	if [ $? -eq 0 ]; then
		#" user exists"
		echo 0
	else
		# "No user"
		echo 1
	fi
}


function showuse  {
	echo -e "Pass an existing username to the script." 
	echo -e "User will be disabled and homedir tarred and gzipped."
}

if [ $(id -u) -eq 0 ]; then
	CURRDIR=$(pwd)
	cd /home
	
	# We need one parameter, check for it...
	if [ ! $# -eq 1 ]; then
		showuse
		exit 1
	fi

	USRNAME=$1
	# first check if user exists and is not root, then we do stuff
	if [ $USRNAME = "root" ]; then
		echo 'Cannot disable root account!!'
		exit 3
	fi
	
	USREXISTS=$(check_user "$USRNAME")
	if [ "$USREXISTS" == 0 ]; then
		# read homedir from passwd
		HOMEDIR=$(getent passwd "$USRNAME" | cut -d : -f 6)
		echo "User ${USRNAME} exists, home directory in :${HOMEDIR}"

		# all set, let's expire, lock and set the shell to a non login shell
		echo "Locking user ${USRNAME}..."
		usermod --lock --expiredate 1 -s /bin/false "$USRNAME"
		
		# save the homedir, delete it only if tar is successful
		if [ -e "$HOMEDIR" ]; then
			ARCHIVENAME="${USRNAME}.tar.gz"
			echo "Archiving home directory in ${ARCHIVENAME} ..."

			tar czf $ARCHIVENAME $HOMEDIR && rm -rf $HOMEDIR
		fi
	else
		echo "User ${USRNAME} does not exist on system."
		exit 2
	fi
    
    cd "$CURRDIR"

else
        echo "must be root"
        exit 0
fi





