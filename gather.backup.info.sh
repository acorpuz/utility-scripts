#!/bin/bash
#
# Get needed info from servers to organize backup.
#	Run as root, summary in $outfile
#

if [ $(id -u) -eq 0 ]; then
    outfile=summary.txt
    echo -e "##################################################################\n\t\t"`date +%c`"\n\t\tHost:\t"\
            `uname -n`"\n\t\tkernel:\t"`uname -r`"\n##################################################################">$outfile
    
    # get used diskspace of dirs to be backed up
    echo -e "\t-------------------- dir use --------------------">> $outfile
    du -hs /var/www/ /var/local/ /usr/local/bin/ /etc/ /home/ >> $outfile
    echo -e "\t---------------- end dir use --------------------/n">> $outfile

    # get used diskspace
    echo -e "\t-------------------- disk use --------------------">> $outfile
    df -h >> $outfile
    echo -e "\t---------------- end disk use --------------------n/">> $outfile
     
    # get total size of mysql database
    echo -e "\t-------------------- database size --------------------">> $outfile
    ls -lh /var/lib/mysql/|grep total >> $outfile
    echo -e "\t---------------- end database size --------------------n/">> $outfile

    # get list of installed software
    echo -e "\t-------------------- list installed software --------------------">> $outfile
    dpkg --get-selections >> $outfile
    echo -e "\t---------------- end list installed software --------------------">> $outfile

else
  echo "must be root"
  exit 0
fi
