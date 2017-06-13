#!/bin/bash
#
# disable_user.sh
#
# ####################################################################
# Description:  Disable users; also tar home directory and remove 
#               uncompressed dir.
#
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 12.07.2016 11:04:54 CEST
# ======== Changelog ========
# 2016-01-12 bioadmin <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Initial script
#
# 2016-07-12  bioadmin  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Clean-up script, add comments, made as function so you can pass 
#   the username you want disabled to script. Added more control functions
#   (check_user, check_login, read_home) 
#
# ####################################################################


function check_user {
    # Check if user exists on system; returns 0 if exists, 1 if non exists
    # Needs username as only parameter
    local USR
    USR="$1"
    getent passwd "$USR"  > /dev/null
    if [ $? -eq 0 ]; then
        #" user exists"
        echo 0
    else
        # "No user"
        echo 1
    fi
}


function showuse  {
    echo -e "Pass an existing username to the script." 
    echo -e "User will be disabled and home directory tarred and gzipped."
}

if [ "$(id -u)" -eq 0 ]; then
    CURRDIR=$(pwd)
    cd /home
    
    # We need one parameter, check for it...
    if [ ! $# -eq 1 ]; then
        showuse
        exit 1
    fi

    USRNAME=$1
    # first check if user exists and is not root, then we do stuff
    if [ "$USRNAME" = "root" ]; then
        echo 'Cannot disable root account!!'
        exit 3
    fi
    
    USREXISTS=$(check_user "$USRNAME")
    if [ "$USREXISTS" == 0 ]; then
        # find last login time
        echo "User ${USRNAME} last logged in" "$(lastlog -u "${USRNAME}" | tail -n1 | cut -c44-)"

        # read homedir from passwd
        HOMEDIR=$(getent passwd "$USRNAME" | cut -d : -f 6)
        echo "User ${USRNAME} exists, home directory in :${HOMEDIR}"

        read -p "Disable account for ${USRNAME} and save and delete contents of ${HOMEDIR}? [y/N]" ans
        case ${ans} in
            y|Y )
                # all set, let's expire, lock and set the shell to a non login shell
                echo "Locking user ${USRNAME}..."
                usermod --lock --expiredate 1 -s /bin/false "$USRNAME"
                echo "Done."
                
                # save the homedir, delete it only if tar is successful
                if [ -e "$HOMEDIR" ]; then
                    ARCHIVENAME="${USRNAME}.tar.gz"
                    echo "Archiving home directory in ${ARCHIVENAME}; home dir will be removed  ..."

                    tar -czvf "$ARCHIVENAME" "$HOMEDIR" && rm -rf "$HOMEDIR"
                    chmod 0600 "$ARCHIVENAME"
                    
                    echo "Done."
                else
                    echo "Home directory ${HOMEDIR} not found, exiting..."
                    exit 4
                fi
            ;;
            * )
                echo "Account for ${USRNAME} left untouched."
            ;;
        esac

    else
        echo "User ${USRNAME} does not exist on system."
        exit 2
    fi
    
    cd "$CURRDIR"
    exit 0
else
        echo "must be root"
        exit 1
fi

