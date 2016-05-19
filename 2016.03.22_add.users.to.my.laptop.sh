#!/bin/bash
#
# 2016.03.22_add.users.to.my.laptop.sh
#
# ####################################################################
# Description: add users to my local PC
#
#
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 22.03.2016 12:52:01 CET
# ======== Changelog ========
# 2016-03-22 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
#
# *
#
#
#
# ####################################################################

addUserPass () {
	USRNAME=${1}
	USRPASS=${2}
	CRYPTPASS=$(perl -e 'print crypt($ARGV[0], "password")' $USRPASS)
	useradd -m -p $CRYPTPASS $USRNAME	
}


if [ $(id -u) -eq 0 ]; then

	# add needed groups
	groupadd biznas

	# add user accounts
	addUserPass luigra luiginomsi
	usermod -a -G biznas luigra
	
	addUserPass daniel daniel
	usermod -a -G biznas daniel
	
	addUserPass guido guido
	usermod -a -G biznas guido
	
	addUserPass loredana loredana
	usermod -a -G biznas loredana
	
	addUserPass "3uss" LoryMJ_3USS

	# create mount for biznas share
	mkdir /media/biznas_public
	chown root:biznas /media/biznas_public
	chmod 1777 /media/biznas_public
	
	# create mount for luigi biznas share
	mkdir /home/luigra/biznas
	chown luigra: /home/luigra/biznas
	
else
	echo "run as root."
	exit 1
fi	
