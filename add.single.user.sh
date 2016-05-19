#!/bin/bash

USRNAME=${1}
USRPASS=$USRNAME"_0000"
CRYPTPASS=$(perl -e 'print crypt($ARGV[0], "password")' $USRPASS)
useradd -m -p $CRYPTPASS $USRNAME
passwd -e $USRNAME
echo "User $USRNAME added."
