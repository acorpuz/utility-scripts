#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  pepcomposer_cleanup.py
#
# ####################################################################
# Description:  Clean-up old (>14 days) pepcomposer jobs. Note that
#               there are example directories that must be preserved
#               (see list at end of script)
#
# Tasks:
#       *)  Check /var/www/pepcomposer/jobs/<job_id>/<job_id.log> for
#           job status; if status = finished then last modified date is
#           when job finished. Use this to make a list of jobs to check.
#       *)  Run through the list and extract all finished jobs older
#           than 14 days that are not example jobs
#       *)  For each job to delete save the following info somewhere:
#           - job_id and completed date & time
#           - deletion date
#           - complete_models directory
#           - input_parameters.info file
#
# TODO: debug logging errors.
# --------------------------------------------------------------------
# 2017 Sapienza - department of bioinformatics
#
# Created 2017/02/16 12:55:58
#
# ======== Changelog ========
# 2017-02-16  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Script re-written in python
#
# 2017-02-28  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Final script, needs to be debugged on production server
#
# 2017-03-09  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added skipping files to script. Activated all parts.
#
# 2017-03-16  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added handling for when script status is "error" (delete after 14 days)
#
# 2017-04-06  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Added logging to specific and global file.
#
# 2017-04-11  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Refactored delete job code and added logging to global script.
#   Activated final script on production server
# ######################################################################
import os
import shutil
import sys
import time
import fileinput
import logging
from logging.handlers import TimedRotatingFileHandler
from logging import FileHandler
from logging import StreamHandler

#DEBUG_MODE = True
DEBUG_MODE = False

pepcomposer_path = "/var/www/pepcomposer/"  # check for trailing slash
# delete this on production machine, needed only for local testing
#if DEBUG_MODE: pepcomposer_path = "tmp_pepcomposer" + pepcomposer_path
# end delete
pepcomposer_jobs_dir = os.path.join(pepcomposer_path,"jobs")
pepcomposer_jobs_archive_dir = os.path.join(pepcomposer_path, "archived_jobs")
pepcomposer_log = os.path.join(pepcomposer_jobs_archive_dir,  "pepcomposer.log")

time_period = 14  # in days
date_format_string = "%Y_%m_%d-%H:%M:%S"

JOB_STATUS_FINISHED = "finished"
JOB_STATUS_ERROR = "error"
JOB_STATUS_MISSING = "missing"

jobs_path_check_ok = False
path_check_ok = False

sample_jobs = [
    "1ELW_receptor56c731973570a",
    "1H6W_receptor_W10456c734e9afdc5",
    "1N7F_receptor_ILE1956c842213a7d2",
    "1NVR_receptor_F7456c9978faf9b6",
    "1TW6_receptor_L54_56cae2cddb845",
    "1UOP_receptor_W595_56cae50086814",
    "2B6N_222_8_ennesimo56e1b80ba97ea",
    "2B9H_receptor14810all56cc76d84a1e5",
    "2V3S_2156d01f62b370a",
    "2XFX_155_1256d1c83a4ef27",
    "3LNY_22_corretto56e8af8853db2",
    "3MMG_172_56e94064af26a",
    "3NJG_92_1056eae58e1261a",
    "3vqg_19_56f34498642f9",
    "4ds1_61_8_56f57d702ccc5",
    "4NNM_25_56f706a78c944",
    "4q6h_20_56f8fa246775e",
    "4QBR_74_56fafac4d63d8",
    "3NFK_19_56fd120b9589d",
    "3BFW_13_56fce5ba3ed4f",
    "3GQ1_22_56fd1c483f7f8",
    "2oy2_no_zn9_75_8_57023a4424d62",
    "3bsq_181_5700fbbc33e72",
    "2oxw_76_8_atoms_57027bb972dae",
    "3ch8_sin_atom_30_570236d56e63b",
    "1NTV_F13656c996a2c6c04",
    "3brl_83_5700fd1434a2f",
    "1N12_receptor_VAL7356c83e85f200b",
    "3D1E_175_10_56d37b6c396b1",
    "3obq_64_1056eae79a8b271",
    "2W0Z_5056d0211351d4f",
    "2W10_5156d0221bc187c",
    "4VRI_Ile98_56f91754b19bd",
    "1SVZ_W164_56fa40504d54e",
    "2QAB_54_10_56e1be078b388",
    "3IDG_94_10_56d37e28c9280",
    "3JZO_Val70_56fafc61e59c3",
    "3upv_77_8_56f1ebe0ef598",
    "4dgy_10856f56fdc086b9",
    "4j8s_25_10_56f85d30ce305",
    "4n7h_18_56f8f9f7c4ff3",
    "4WLB_69A_56f912bbb92d7",
    "1OU8_receptor_ASN4956ca43db37547",
    "2HPL_receptor27all56cc78527d6c1",
    "2O02_receptor491056cc7a52d18ee",
    "3q47_73_10_56ef36752cf1e",
    "4eik_36_56f7080a3bd6b",
    "3DS1_L64_56fafcbd7fb5d",
    "alfredo_test656bc5cbab5740",
    "alfredo_testanna256c05614cec43",
    "1DXP_154_A_57058b2c3d4f3"
]

need_to_save_list = [
    "complete_models",
    "input_parameters.info",
    "input_parameters.info_new",
    "input_parameters.info_original"
]

def found_in_examples(job_id):
    # search for job in sample list
    found_job = False
    for element in sample_jobs:
        if element == job_id:
            found_job = True
            break
    return found_job

def check_if_root():
    user = os.getuid()
    if user != 0:
        print "Please run as root..."
        sys. exit(1) 

def delete_job(full_path_to_job_dir):
    # delete job passed as path and log to global log
    globalLogger.warn ("Deleting path " + full_path_to_job_dir + "...")
    shutil.rmtree(full_path_to_job_dir)
    globalLogger.warn ("Path " + full_path_to_job_dir + " deleted.")


# checking root status, but only if not debugging
if not DEBUG_MODE:
    check_if_root()

# checking paths
if not os.path.exists(pepcomposer_path):
    if DEBUG_MODE:
        os.makedirs(pepcomposer_path)
        path_check_ok = True
else:
    path_check_ok = True
    
if not os.path.exists(pepcomposer_jobs_dir):
    if DEBUG_MODE:
        os.makedirs(pepcomposer_path)
        jobs_path_check_ok = True
else:
    jobs_path_check_ok = True

if not os.path.exists(pepcomposer_jobs_archive_dir):
    os.mkdir(pepcomposer_jobs_archive_dir,2775)
    
if DEBUG_MODE:
    print ("********** Start Tests **********\n")
    print ("Variables assignments")
    print ("==============================")
    print "pepcomposer_path = " + pepcomposer_path
    print "pepcomposer path exists:" + str(path_check_ok)
    print "pepcomposer_jobs_dir = " + pepcomposer_jobs_dir
    print "pepcomposer jobs path exists:" + str(jobs_path_check_ok)
    print "pepcomposer_jobs_archive_dir = " + pepcomposer_jobs_archive_dir
    print "pepcomposer_log = " + pepcomposer_log
    print "time_period = " + str(time_period) + " (days)"
    print "JOB_STATUS_FINISHED = " + JOB_STATUS_FINISHED
    print "JOB_STATUS_MISSING = " + JOB_STATUS_MISSING
    print "JOB_STATUS_ERROR = " + JOB_STATUS_ERROR
    print "sample_jobs = ", sample_jobs
    print ("==============================")
    print ("End Variables assignments\n\n")
    
    not_sample = "NOT A SAMPLE JOB"
    is_sample = "4ds1_61_8_56f57d702ccc5"
    print "Is " + not_sample + " an example? " + str(found_in_examples (not_sample))
    print "Is " + is_sample + " an example? " + str(found_in_examples (is_sample))
    print ("\n*********** End Tests ***********\n")
    
if path_check_ok:
    # mtime returns last modified time in seconds from epoch,
    # converting time_period in days to seconds
    num_days = 86400 * time_period  # in seconds
    now = time.time()               # in seconds

    # set up global logging, log to file and to console
    globalLogger = logging.getLogger('global log')
    globalLogger.setLevel(logging.INFO)

    console = logging.StreamHandler()
    console.setLevel(logging.DEBUG)
    console_format=logging.Formatter('%(name)-12s: %(message)s')
    console.setFormatter(console_format)

    global_log_handler = TimedRotatingFileHandler(pepcomposer_log, when='W6')
    global_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    global_log_handler.setFormatter(global_formatter)
    globalLogger.addHandler(global_log_handler)
    globalLogger.addHandler(console)

    for dirs in os.listdir(pepcomposer_jobs_dir):
        # find all jobs in job dir older than "num_days" period of days
        job_name = dirs
        job_path = os.path.join(pepcomposer_jobs_dir, dirs)
        if os.path.isdir(job_path): 
            archive_path = os.path.join(pepcomposer_jobs_archive_dir, job_name)
            last_modified = os.path.getctime(job_path)

            if now - num_days > last_modified:
                globalLogger.info("Processing job " + job_name)
                # for each job older than "time_period",
                # check if it is a sample job
                job_status = ""
                if not found_in_examples(job_name):
                    # read job_name.log to check for job status
                    log_file=os.path.join(job_path,job_name + ".log")
                    if os.path.exists(log_file):
                        with open (log_file,'r') as fo:
                            job_status = fo.readline()
                    else:
                        job_status = JOB_STATUS_MISSING

                    if job_status == JOB_STATUS_FINISHED: 
                        temp_job_dir = os.path.join(pepcomposer_jobs_dir, job_name + "_tmp")
                        job_log = os.path.join(temp_job_dir, "operations.log")
                        curr_date = time.strftime(date_format_string)
                        job_end_date = time.gmtime(os.path.getmtime(job_path))
                        job_end_date = time.strftime(date_format_string, job_end_date)
                        # Clear temp dir if exists (failsafe for old dirs)
                        if os.path.exists(temp_job_dir):
                            shutil.rmtree(temp_job_dir)       
                        os.makedirs(temp_job_dir)

                        # add local job formatter
                        job_log_handler = FileHandler(job_log)
                        # create formatter and add it to the handlers
                        job_log_formatter = logging.Formatter('%(message)s')
                        job_log_handler.setFormatter(job_log_formatter)
                        globalLogger.addHandler(job_log_handler)

                        globalLogger.info("Archiving job " + job_name + " on " + str(curr_date))
                        globalLogger.info("="*40)
                        globalLogger.info("Job completed on " + job_end_date)
 
                        # save complete model directory
                        # and input_parameters files
                        for obj in need_to_save_list:
                            target = os.path.join(job_path, obj)
                            destination = os.path.join(temp_job_dir, obj)
                            if os.path.exists(target):
                                if os.path.isdir(target):
                                    shutil.copytree(target, destination)
                                    globalLogger.info("Saving " + obj + "...")
                                else:
                                    shutil.copy2(target, temp_job_dir)
                                    read_data=""
                                    with open(target,'r') as f:
                                        read_data=f.read()
                                    globalLogger.info("File " + obj)
                                    globalLogger.info("*"*40)
                                    globalLogger.info(read_data)
                                    globalLogger.info("*"*40)
                        job_log_handler.close()
                        globalLogger.removeHandler(job_log_handler)

                        if not DEBUG_MODE:
                            # tar.gz everything in temp job directory
                            try:
                                globalLogger.info("Archiving files...")
                                shutil.make_archive(archive_path, "gztar", temp_job_dir)
                                globalLogger.info("Files archived in " + archive_path + ".tar.gz")
                                # delete job and clean-up
                                delete_job(job_path)
                                delete_job(temp_job_dir)
                            except:
                                globalLogger.error("Error archiving file!")
                    elif job_status == JOB_STATUS_MISSING:
                        globalLogger.warn ("Empty or incomplete job, deleting")
                        if not DEBUG_MODE:
                            delete_job(job_path)
                    elif job_status == JOB_STATUS_ERROR:
                        globalLogger.warn ("Misconfigured job, deleting")
                        if not DEBUG_MODE:
                            delete_job(job_path)
                else:
                    # if sample JOB --> do nothing
                    globalLogger.info ("Skipping example job " + job_name)
        else:
            globalLogger.info("Skipping file " + job_name)
    
    # all done, close logging objects and exit
    sys.exit(0)

else:
    if not path_check_ok:
        globalLogger.warn("ERROR!!! Pepcomposer directory not found in ", pepcomposer_path, "!")
        #print "ERROR!!! Pepcomposer directory not found in ", pepcomposer_path, "!"
    if not jobs_path_check_ok:
        globalLogger.warn("ERROR!!! Pepcomposer jobs directory not found in ", pepcomposer_jobs_dir, "!")
        #print "ERROR!!! Pepcomposer jobs directory not found in ", pepcomposer_jobs_dir, "!"
    sys.exit(1)
