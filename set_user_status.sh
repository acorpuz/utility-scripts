#!/bin/bash
#
# set_user_status.sh
#
# ####################################################################
# Description:  shell script to lock/unlock a user. Script determines if
#               user exists and recovers user data from passwd file. If 
#               user is locked it asks if it needs to be unlocked and 
#               vice versa.
# Parameter: username to lock/unlock.
#
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 20.12.2016 10:57:15 CET
# ======== Changelog ========
# 2016-12-20 bioangel <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Initial script
#
# 2017-03-02  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added end of commands status feedback. Reworked tar command.
#
# ####################################################################

# Load needed helper functions
. /lib/lsb/init-functions

showuse () {
    echo -e "Pass an existing username to the script.\nUser will be enabled or disabled."
}

check_user () {
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

# We need one parameter (the username), check for it...
if [ ! $# -eq 1 ]; then
    showuse
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    usr_name=$1
    # first check if user exists and is not root, then we do stuff
    if [ "$usr_name" = "root" ]; then
        log_warning_msg 'Cannot disable root account!!'
        exit 3
    fi
    
    usr_exists=$(check_user "$usr_name")
    if [ "$usr_exists" == 0 ]; then
        curr_dir="$(pwd)"
        # read homedir from passwd
        home_dir=$(getent passwd "$usr_name" | cut -d : -f 6)
        echo "User ${usr_name} exists, home directory in :${home_dir}"

        # get account status (locked/unlocked)
        account_status=$(passwd -S "$usr_name" | cut -d " " -f2)
        
        if [ "$account_status" == "L" ]; then
            # account is locked, ask to re-enable (default is no)
            read -p "Account for ${usr_name} is locked; enable account? [y/N]" ans
            case ${ans} in
                y|Y )
                    echo "Un-locking user ${usr_name}..."
                    usermod --unlock --expiredate "" -s /bin/bash "$usr_name"
                    echo "User ${usr_name} unlocked"
                ;;
                * )
                    echo "Account for ${usr_name} left locked."
                ;;
            esac

        else
            # account is enabled, ask to lock (not strictly true but good for our purposes)
            read -p "Account for ${usr_name} is enabled; lock account and delete contents of ${home_dir}? [y/N]" ans
            case ${ans} in
                y|Y )
                    echo "Locking user ${usr_name}..."
                    usermod --lock --expiredate 1 -s /bin/false "$usr_name"
                    echo "User ${usr_name} locked"
                    #delete contents of home directory
                    if [ -e "$home_dir" ]; then
                        project_name=$(basename "${home_dir}")
                        project_path=$(dirname "${home_dir}")
                        echo "Clearing home directory ${home_dir} ..."
                        cd "$project_path"
                        tar -czf "${project_name}.tar.gz" "$project_name" && rm -rf "${home_dir}*"
                        echo "Home directory ${home_dir} cleared, contents saved as ${project_name}.tar.gz"
                    else
                        echo "Home directory ${home_dir} not found, exiting..."
                        exit 4
                    fi
                ;;
                * )
                    echo "Account for ${usr_name} left enabled."
                ;;
            esac        
        fi
        
    else
        echo "User ${USRNAME} does not exist on system."
        exit 2
    fi
    # all done
    cd "$curr_dir"
    exit 0
    
else
    echo "must be root"
    exit 1
fi

