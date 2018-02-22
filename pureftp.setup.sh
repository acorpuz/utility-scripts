#!/bin/bash

# Script di setup di pureftp


if [ $(id -u) -eq 0 ]; then
    # installall base package with mysql support
    apt-get update
    apt-get install pure-ftpd-mysql
    # add needed group and user, user has no login shell and no homedir
    groupadd -g 2015 ftpgroup
    useradd -u 2015 -s /bin/false -d /bin/null -c "pureftp user" -g ftpgroup ftpuser
    
    # create pureftpd directives
    echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
    echo "yes" > /etc/pure-ftpd/conf/CreateHomeDir
    
    # create database and tables using create script
    mysql -uroot -p
    
    exit 0
else
  echo "must be root"
  exit 0
fi
