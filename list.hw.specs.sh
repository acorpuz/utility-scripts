#!/bin/bash

outfile=hardware.txt
touch ./$outfile
/dev/null>$outfile
ip a >> $outfile
cat /proc/meminfo | grep MemTotal$outfile >> $outfile
