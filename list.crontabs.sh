#!/bin/bash
for user in $(cut -f1 -d: /etc/passwd);
do
	echo "======= crontab for " $user " ======="
	crontab -u $user -l
	echo " "
done

