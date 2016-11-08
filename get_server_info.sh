#!/bin/bash
#
# get_server_info.sh
#
# ####################################################################
# Description: 	Get info from servers to fill out server document.
#				Reuses ideas from inxi script.
#
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 05.09.2016 16:25:31 CEST
# ======== Changelog ========
# 2016-09-05 bioangel <angel<dot>corpuz<dot>jr@gmail<dot>com>
#
# *
#
#
#
# ####################################################################

#if [ "$(id -u)" -eq 0 ]; then
	## FQDN
	echo -e "FQDN:\t$( hostname -A )"

	##IP and GW 
	echo -e "IP/GW:\t$( ip r )"
	

#else
#	echo "run as root"
#	exit 1
#fi
