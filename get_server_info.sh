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
# ####################################################################

## FQDN
echo "########################################"
echo -e "Hardware info for $( hostname --fqdn )"
echo -e "Running $( uname -a)"
echo "########################################"
echo -e "____\\tCPU\\t____"
lscpu | grep 'Architecture\|CPU\|Vendor ID\|Model name' | grep -v 'On-line\|NUMA\|op-mode'
echo "--------------------"
echo -e "____\\tMemory\\t____"
free -h
echo "--------------------"
echo -e "____\\tHDD Use\\t____"
df -hxtmpfs
echo "--------------------"
##IP and GW 
echo -e "____\\tNetwork\\t____"
echo -e "Interfaces:\\n$( ip link show )"
echo -e "\\n"
echo -e "Gateway:\\n$( ip r )"
