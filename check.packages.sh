#!/bin/bash
################################################################################
# Script to determine the status of a list of R packages.
#	If the status is not ok, it generates a list of needed/updatable packages
#	and mails it locally to the root user.
#	The list needs to be saved in the current dir as RPackageList.txt,
#	one package name per line.
#
# Missing packages are tracked in the issues.txt file
#	First we create an empty file, if it stays empty all is OK,
#	otherwise we mail it's contents to srvadmin@localhost.
#
# Script will be put in cron so as to run 1/week.
################################################################################


# First we need the status of the packages in R
# touch ./RPackages.R
# echo "chooseBioCmirror(graphics = getOption(\"menu.graphics\"),ind=3)" > RPackages.R
# echo "chooseCRANmirror(graphics = getOption(\"menu.graphics\"), ind = 49)" >> RPackages.R
# echo "setRepositories(graphics = getOption(\"menu.graphics\"), ind = c(1,2,3,4,5,6))" >> RPackages.R
# echo "inst <- packageStatus()" >> RPackages.R
# echo "inst[c(\"Package\", \"Version\", \"Status\")]" >> RPackages.R

#R --vanilla -q CMD BATCH RPackages.R
#res=$(Rscript RPackages.R cluster)
#echo "Package status: "$res
#R --no-save << 'EOF'
#r_check_status<-function()
#{
#	chooseBioCmirror(graphics = getOption("menu.graphics"),ind=3)
#	chooseCRANmirror(graphics = getOption("menu.graphics"), ind = 49)
#	setRepositories(graphics = getOption("menu.graphics"), ind = c(1,2,3,4,5,6))
  #
#  if (!require(x,character.only = TRUE))

# Check installed packages
#chooseBioCmirror(graphics = getOption("menu.graphics"),ind=3)
#chooseCRANmirror(graphics = getOption("menu.graphics"), ind = 49)
#setRepositories(graphics = getOption("menu.graphics"), ind = c(1,2,3,4,5,6))
#inst <- packageStatus()
#inst[c(\"Package\", \"Version\", \"Status\")]
#


# define some file names
outFile=issues.txt
R_refFile=RPackageList.txt


# Blank the issues.txt file
>$outFile

#### Check R packages ####

# This sets-up R mirrors and repositories; not needed for now
#Rscript --vanilla RPackages.R "SETUP"

while read line; do 
  package_name="$line"
  res=$(Rscript --vanilla RPackages.R $package_name)
  if [ "$res" == "[1] FALSE" ]; then
	#echo $package_name "is missing"
	echo $package_name "is missing" >> $outFile
  #else
	#echo $package_name "OK."
  fi
done < $R_refFile

#### Check Python packages #####



#### Check Perl packages #####


# Check for errors and mail file if needed
if [[ -s $outFile ]] ; then
  echo "$outFile has data."
else
  echo "$outFile is empty."
fi

