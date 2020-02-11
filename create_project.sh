#!/bin/bash
#
# create_project.sh
#
# ####################################################################
# Description:  Script to set-up the directory structure of projects
#               that will run on wsmilanetti.iit.uniroma1.it.
#               The script creates the dir structure and USER, assigns
#               the target directory as home to USER and set the
#               correct permissions (2770).
#               User is created with a default password to allow login
#               while physically at the machine.
#               The home directory has a link to a fast directory.
#
# TODO: add switch to delete project/user/group
# TODO: consider migration to Ansible
# --------------------------------------------------------------------
# 2019 Sapienza - department of bioinformatics
#
# Created 2019.08.08
# ======== Changelog ========
# 2019-08-08 bioangel <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Refactored script for wsmilanetti
#
# ####################################################################
/usr/local/src
# Load needed helper functions
. /lib/lsb/init-functions

BASE_PROJECT_PATH="/mnt/projects"
FAST_DIR_PATH="/mnt/fastdir"

function showuse  {
    echo -e "Usage:\t$(basename "$0") project_name"
    echo -e "\tPass a PROJECT_NAME to the script."
    echo -e "\tThe directory /mnt/projects/PROJECT_NAME will be created as "
    echo -e "\thome directory of the user PROJECT_NAME."
}

# We need one parameter, check for it...
if [ ! $# -eq 1 ]; then
    showuse
    exit 99
fi
# check for root
if [ "$(id -u)" -eq 0 ]; then
    project_name="$1"
    # remove white space from name
    project_name="$(echo "${project_name}" | tr -d '[:space:]')"
    #remove capitals from project_user
    project_user="$(echo -e "${project_name,,}")"
    project_group="$project_user"
    path_to_project="${BASE_PROJECT_PATH}/${project_name}"

    # Check project directory
    if [ -d "$path_to_project" ]; then
        log_warning_msg "${path_to_project} exists. Exiting."
        exit 1
    fi
    # Check project group
    if [ "$(getent group "${project_group}")" ]; then
        log_warning_msg "${project_group} group exists."
        exit 1
    fi
    log_action_begin_msg "Setting up project ${project_name}"

    log_action_cont_msg "Creating group ${project_group} "
    addgroup "$project_group"

    log_action_cont_msg "Adding user $project_user to system"
    # generate a random passwd
    passwd=$(pwgen 6)
    usrpass="${project_name}_${passwd}"
    # add the user
    cryptpass=$(perl -e 'print crypt($ARGV[0], "password")' "$usrpass")
    useradd -m -d "$path_to_project" -g "$project_group" -p "$cryptpass" "$project_user"

    log_action_cont_msg "Setting up $project_name permissions"
    chown "$project_user":"$project_group" "$path_to_project"
    chmod 2770 "$path_to_project"

    log_action_cont_msg "Creating link in ${path_to_project} to ${FAST_DIR_PATH}"
    mkdir -p "${FAST_DIR_PATH}/${project_name}"
    chown "$project_user":"$project_group" "${FAST_DIR_PATH}/${project_name}"
    chmod 2770 "${FAST_DIR_PATH}/${project_name}"
    ln -s "${FAST_DIR_PATH}/${project_name}" "${path_to_project}/fastdir"

    # all done, report outcome
    log_action_end_msg 0

    log_success_msg "Project ${project_name} created successfully."

    echo "Project ${project_name} details:"
    echo -e "\t*) Project directory created in ${path_to_project}"
    echo -e "\t*) User ${project_user} added with password ${usrpass}"
    echo -e "\t*) Password login is available only at the machine."
    echo -e "\t*) Connect to server with:\tssh ${project_user}@$(hostname --fqdn),"
    echo -e "\tyou will need to request a ssh certificate to login."

    exit 0
else
    echo "Run as root."
    exit 1
fi

