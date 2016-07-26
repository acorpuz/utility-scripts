#!/bin/bash
#
# add.single.user.sh
#
# ####################################################################
# Description: 	Adds a single user to system with a random password.
#				Need pwgen program installed.
#				Added user has password set to expire to force a password
#				change at his first login.
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 07.07.2016 12:59:53 CEST
# ======== Changelog ========
# 2016-07-07 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Cleanup of script
# * Added comments and other checks
#
#
# ####################################################################


# check for root
if [ $(id -u) -eq 0 ]; then
	USRNAME=${1}
	
	# generate a random passwd
	PASSWD=$(pwgen 4)
	USRPASS=${USRNAME}"_"${PASSWD}

	# add the user
	CRYPTPASS=$(perl -e 'print crypt($ARGV[0], "password")' $USRPASS)
	useradd -m -p "$CRYPTPASS" "$USRNAME"

	# expire password
	passwd -e $USRNAME
	
	# All done, show details.
	echo "User $USRNAME added with password $USRPASS"
	
	exit 0
else
	echo "Run as root."
	exit 1
fi
