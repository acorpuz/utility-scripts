#!/bin/bash
#
# pepcomposer_cleanup.sh
#
# ####################################################################
# Description: 	Clean-up old (>14 days) pepcomposer jobs. Note that 
#				there are example directories that must be preserved
#				(see list at end of script)
#
# Tasks:
#		*)  Check /var/www/pepcomposer/jobs/<job_id>/<job_id.log> for 
#			job status; if status = finished then last modified date is
#			when job finished. Use this to make a list of jobs to check.
#		*)	Run through the list and extract all finished jobs older 	
#			than 14 days that are not example jobs
#			[echo ${Array1[@]} ${Array2[@]} | tr ' ' '\n' | sort | uniq -u]
#		*)	For each job to delete save the following info somewhere:
#			- job_id and completed date & time
#			- deletion date
#			- complete_models directory
#			- input_parameters.info file
#
# TODO: what happens when script status is not finished?
# TODO: what happens to other files (.zip files, .pdb files)?
# --------------------------------------------------------------------
# 2016 Sapienza - department of bioinformatics
#
# Created 27.12.2016 13:00:46 CET
# ======== Changelog ========
# 2016-12-27 bioangel <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Initial script, WIP
#
# 2017-02-09  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Finish script and testing 
#
#2017-02-14  bioangel  <angel<dot>corpuz<dot>jr@gmail<dot>com>
# * Activated script in crontab
#	@weekly	/bin/bash /root/Utility-scripts/pepcomposer_cleanup.sh
# ####################################################################

PEPCOMPOSER_PATH="/var/www/pepcomposer"
PEPCOMPOSER_JOBS_DIR="${PEPCOMPOSER_PATH}/jobs"
PEPCOMPOSER_JOBS_ARCHIVE_DIR="${PEPCOMPOSER_PATH}/archived_jobs"
PEPCOMPOSER_LOG="${PEPCOMPOSER_JOBS_ARCHIVE_DIR}/pepcomposer.log"
TIME_PERIOD="14"	# in days
JOB_STATUS_FINISHED="finished"

A_EXAMPLE_DIRS=( 1ELW_receptor56c731973570a 1H6W_receptor_W10456c734e9afdc5 \ 
1N7F_receptor_ILE1956c842213a7d2 1NVR_receptor_F7456c9978faf9b6 \
1TW6_receptor_L54_56cae2cddb845 1UOP_receptor_W595_56cae50086814 \
2B6N_222_8_ennesimo56e1b80ba97ea 2B9H_receptor14810all56cc76d84a1e5 \
2V3S_2156d01f62b370a 2XFX_155_1256d1c83a4ef27 3LNY_22_corretto56e8af8853db2 \
3MMG_172_56e94064af26a 3NJG_92_1056eae58e1261a 3vqg_19_56f34498642f9 \
4ds1_61_8_56f57d702ccc5 4NNM_25_56f706a78c944 4q6h_20_56f8fa246775e \
4QBR_74_56fafac4d63d8 3NFK_19_56fd120b9589d 3BFW_13_56fce5ba3ed4f \
3GQ1_22_56fd1c483f7f8 2oy2_no_zn9_75_8_57023a4424d62 3bsq_181_5700fbbc33e72 \
2oxw_76_8_atoms_57027bb972dae 3ch8_sin_atom_30_570236d56e63b 1NTV_F13656c996a2c6c04 \
3brl_83_5700fd1434a2f 1N12_receptor_VAL7356c83e85f200b 3D1E_175_10_56d37b6c396b1 \
3obq_64_1056eae79a8b271 2W0Z_5056d0211351d4f 2W10_5156d0221bc187c \
4VRI_Ile98_56f91754b19bd 1SVZ_W164_56fa40504d54e 2QAB_54_10_56e1be078b388 \
3IDG_94_10_56d37e28c9280 3JZO_Val70_56fafc61e59c3 3upv_77_8_56f1ebe0ef598 \
4dgy_10856f56fdc086b9 4j8s_25_10_56f85d30ce305 4n7h_18_56f8f9f7c4ff3 \
4WLB_69A_56f912bbb92d7 1OU8_receptor_ASN4956ca43db37547 2HPL_receptor27all56cc78527d6c1 \
2O02_receptor491056cc7a52d18ee 3q47_73_10_56ef36752cf1e 4eik_36_56f7080a3bd6b \
3DS1_L64_56fafcbd7fb5d alfredo_test656bc5cbab5740 alfredo_testanna256c05614cec43 \
1DXP_154_A_57058b2c3d4f3 )

if [ "$(id -u)" -eq 0 ]; then
	a_jobs_dirs=()

	old_pwd="$(pwd)"
	cd "$PEPCOMPOSER_JOBS_DIR"
	
	# check paths	
	if [ ! -e "$PEPCOMPOSER_JOBS_ARCHIVE_DIR" ]; then
		mkdir -p "$PEPCOMPOSER_JOBS_ARCHIVE_DIR"
	fi	
	if [ ! -e "$PEPCOMPOSER_PATH" ]; then
		echo "ERROR!!! Pepcomposer directory not found in ${PEPCOMPOSER_PATH}!"
		exit 1
	fi
	if [ ! -e "$PEPCOMPOSER_JOBS_DIR" ]; then
		echo "ERROR!!! Pepcomposer jobs directory not found in ${PEPCOMPOSER_JOBS_DIR}!"	
		exit 1
	fi
		
		
	# find all jobs in job_dir older than 14 days (use reference file to determine status)
	
	a_jobs_dirs=$(find -maxdepth 1 -path './[^.]*' -type d -mtime +${TIME_PERIOD});
	
	# make sure they don't belong to excluded list and generate final list
	final_list=$(echo "${A_EXAMPLE_DIRS[@]}" "${a_jobs_dirs[@]}" | tr ' ' '\n' | sort | uniq -u)
	

	# ... do stuff (backup/save files, log jobnames, etc)
	for i in $final_list; do
		job_name="$i"
		# get jobs status
		if [ -e "${job_name}/${job_name}.log" ]; then
			job_status=$(cat "${job_name}/${job_name}.log")
		else
			echo "Empty or incomplete job, deleting"
			rm -rf "$job_name"
			job_status=""
		fi
		
		if [ "$job_status" = "$JOB_STATUS_FINISHED" ]; then
			## save in tmp dir
			#	- job_id and completed date & time
			#	- deletion date
			#	- complete_models directory
			#	- input_parameters.info file
			temp_job_dir="${job_name}_backup"
			curr_date=$(date +%Y_%m_%d-%H:%M:%S)
			job_end_date=$(stat -c %y "${job_name}/${job_name}.log")

			mkdir "$temp_job_dir"
			
			echo -e "Archiving job ${job_name} on ${curr_date}" > "${temp_job_dir}/Operation.log"
			echo -e "=========================================" >> "${temp_job_dir}/Operation.log"
			echo -e "Job ${job_name} completed on ${job_end_date} with the following parameters:" >> "${temp_job_dir}/Operation.log"
			for j in ${job_name}/input_parameters.*; do 
				echo -e "File - $j" >> "${temp_job_dir}/Operation.log"
				echo -e "************************************\n"  >> "${temp_job_dir}/Operation.log"
				cat "${j}" >> "${temp_job_dir}/Operation.log"
				echo -e "\n************************************\n"  >> "${temp_job_dir}/Operation.log"
			done	
			echo -e "================ End log ================\n" >> "${temp_job_dir}/Operation.log"

			# move needed files to temp dir and archive
			mv "${job_name}/complete_models" "$temp_job_dir"
			mv "${job_name}/input_parameters.*" "$temp_job_dir"
			tar czf "${job_name}.tar.gz" "$temp_job_dir"

			# all done!! update global log, move tar to archive dir, delete jobs dir & clean-up
			cat "${temp_job_dir}/Operation.log" >> "$PEPCOMPOSER_LOG"
			mv "${job_name}.tar.gz" "$PEPCOMPOSER_JOBS_ARCHIVE_DIR"
			rm -rf "$job_name"
			rm -rf "$temp_job_dir"
		fi
	done

	# all done
	cd "$old_pwd"
	exit 0
	
else
	
	echo "Run as root."
	exit 1
fi


# ================== List example dirs, do not remove ==================
# "1ELW_receptor56c731973570a"
# "1H6W_receptor_W10456c734e9afdc5"
# "1N7F_receptor_ILE1956c842213a7d2"
# "1NVR_receptor_F7456c9978faf9b6"
# "1TW6_receptor_L54_56cae2cddb845"
# "1UOP_receptor_W595_56cae50086814"
# "2B6N_222_8_ennesimo56e1b80ba97ea"
# "2B9H_receptor14810all56cc76d84a1e5"
# "2V3S_2156d01f62b370a"
# "2XFX_155_1256d1c83a4ef27"
# "3LNY_22_corretto56e8af8853db2"
# "3MMG_172_56e94064af26a"
# "3NJG_92_1056eae58e1261a"
# "3vqg_19_56f34498642f9"
# "4ds1_61_8_56f57d702ccc5"
# "4NNM_25_56f706a78c944"
# "4q6h_20_56f8fa246775e"
# "4QBR_74_56fafac4d63d8"
# "3NFK_19_56fd120b9589d"
# "3BFW_13_56fce5ba3ed4f"
# "3GQ1_22_56fd1c483f7f8"
# "2oy2_no_zn9_75_8_57023a4424d62"
# "3bsq_181_5700fbbc33e72"
# "2oxw_76_8_atoms_57027bb972dae"
# "3ch8_sin_atom_30_570236d56e63b"
# "1NTV_F13656c996a2c6c04"
# "3brl_83_5700fd1434a2f"
# "1N12_receptor_VAL7356c83e85f200b"
# "3D1E_175_10_56d37b6c396b1"
# "3obq_64_1056eae79a8b271"
# "2W0Z_5056d0211351d4f"
# "2W10_5156d0221bc187c"
# "4VRI_Ile98_56f91754b19bd"
# "1SVZ_W164_56fa40504d54e"
# "2QAB_54_10_56e1be078b388"
# "3IDG_94_10_56d37e28c9280"
# "3JZO_Val70_56fafc61e59c3"
# "3upv_77_8_56f1ebe0ef598"
# "4dgy_10856f56fdc086b9"
# "4j8s_25_10_56f85d30ce305"
# "4n7h_18_56f8f9f7c4ff3"
# "4WLB_69A_56f912bbb92d7"
# "1OU8_receptor_ASN4956ca43db37547"
# "2HPL_receptor27all56cc78527d6c1"
# "2O02_receptor491056cc7a52d18ee"
# "3q47_73_10_56ef36752cf1e"
# "4eik_36_56f7080a3bd6b"
# "3DS1_L64_56fafcbd7fb5d"
# "alfredo_test656bc5cbab5740"
# "alfredo_testanna256c05614cec43"
# "1DXP_154_A_57058b2c3d4f3"
