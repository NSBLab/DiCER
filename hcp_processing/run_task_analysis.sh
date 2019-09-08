#!/bin/env bash

#SBATCH --job-name=HCP_tasks
#SBATCH --account=kg98
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2400:00
#SBATCH --mail-user=kevin.aquino@monash.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=32000
#SBATCH -A kg98
#SBATCH --array=1-91


#SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon.txt"
SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon_100_dicer.txt"

export subject=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SUBJECT_LIST})
echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} ----- "
echo -e "\t\t\t --------------------------- \n"

#Load connectome module
module load connectome
module load anaconda/5.0.1-Python2.7-gcc5
export Subjlist=$subject
export StudyFolder=/scratch/kg98/HCP_grayordinates_processed_temporary/
working_hcp_dir=/scratch/kg98/HCP_grayordinates_processed/

task[0]='EMOTION'
task[1]='GAMBLING'
task[2]='LANGUAGE'
task[3]='MOTOR'
task[4]='RELATIONAL'
task[5]='SOCIAL'
task[6]='WM'

# FUNCTION DECLARATIONS (CALLED AFTER)
copying_task_results () {
	# In here copy the task results to somewhere else provided by the argument
	for i in `seq 0 6`;
		do	
			if [ ! -d $working_hcp_dir"/"$subject"/"$1"_taskResults" ]; then
          			mkdir -p $working_hcp_dir"/"$subject"/"$1"_taskResults"
			fi	
			cp -r $StudyFolder"/"$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"/tfMRI_"${task[i]}"_hp200_s2_level2_MSMAll.feat" $working_hcp_dir"/"$subject"/"$1"_taskResults/"
		done
}

regress_out_noise () {
	# First have to split up the regressor file
	preproType=$1
	case $preproType in
		# Here first choose the right regressor either the GMR variant or the DiCER one...
		GMR) totalRegressor=$working_hcp_dir/$subject/$subject"_task_GMsignal.txt" ;;
		DiCER) totalRegressor=$working_hcp_dir/$subject/$subject"_task_dbscan_liberal_regressors.tsv" ;;			
	esac

	echo python split_up_regressor.py -reg $totalRegressor -folderBase $working_hcp_dir/$subject/$preproType"_"
	python split_up_regressor.py -reg $totalRegressor -folderBase $working_hcp_dir/$subject/$preproType"_"

	# In here when you choose what you want to regress, also make copies of original signal
	for i in `seq 0 6`;
	do	
		resultsFolderBase=$StudyFolder"/"$subject"/MNINonLinear/Results/tfMRI_"${task[i]}
		PE[0]='LR'
		PE[1]='RL'
		for pd in `seq 0 1`;
		do
			taskFolder=$resultsFolderBase"_"${PE[pd]}
			# If statement if we are looking at DiCER (done first) then make a copy as well of the original files
			if [ $preproType = "DiCER" ]
			then
				cp $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_Atlas_MSMAll.dtseries.nii" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_standard_Atlas_MSMAll.dtseries.nii"
			fi
			# Get the regressor variable for later use
			regressor=$working_hcp_dir/$subject/$preproType"_"${task[i]}"_"${PE[pd]}".tsv"

			# Now do the regression for each file, first convert to fake nifti then do the regression
			wb_command -cifti-convert -to-nifti $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_Atlas_MSMAll.dtseries.nii" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_"$preproType".nii.gz"
			# Find number of regressors
			nreg=$(awk '{print NF}' $regressor | sort -nu | tail -n 1)
			# Now build up the regressor list as per fsl_regfilt requirement (i.e. needs the list to be like 1,2,3 etc.)
			reg_list="1";
			for (( reg_no=2; reg_no<=1; reg_no++ ));
			do 
				reg_list=$reg_list","$reg_no;
			done			
			# By default if there is only 1 regressor will only spit out 1 value

			# Now do the regression
			fsl_regfilt -i $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_"$preproType".nii.gz" -d $regressor -o $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_REGRESSED_"$preproType".nii.gz" -f $reg_list
			# After this is done, then convert it back to CIFTI
			wb_command -cifti-convert -from-nifti $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_REGRESSED_"$preproType".nii.gz" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_Atlas_MSMAll.dtseries.nii" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_"$preproType"_Atlas_MSMAll.dtseries.nii"
			# now remove the temporary nifti files:
			rm -rf $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_"$preproType".nii.gz" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_FAKE_NIFTI_REGRESSED_"$preproType".nii.gz"
		done
		
	done
}


change_task_input () {
	# Change the inputs to the task analysis! this is done to make it automated and transparent
	preproType=$1

	for i in `seq 0 6`;
	do	
		resultsFolderBase=$StudyFolder"/"$subject"/MNINonLinear/Results/tfMRI_"${task[i]}
		PE[0]='LR'
		PE[1]='RL'
		for pd in `seq 0 1`;
		do
			taskFolder=$resultsFolderBase"_"${PE[pd]}
			# Trick here, copy the preprocessed CIFTI to the default type that is used with the task, this then makes all the code work nicely
			cp $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_"$preproType"_Atlas_MSMAll.dtseries.nii" $taskFolder"/tfMRI_"${task[i]}"_"${PE[pd]}"_Atlas_MSMAll.dtseries.nii"
		done
		
	done
}



# STEP 1: Performing the regession for DiCER and GMR
regress_out_noise "DiCER"
regress_out_noise "GMR"

# STEP 2: Run the task GLMs for the standard protocol:
sh /home/kaqu0001/HCPpipelines/Examples/Scripts/TaskfMRIAnalysisBatch.sh --runlocal
# And copy the results back to a differnt folder
copying_task_results "standard"


# STEP 3: Change the file to now work on the DiCER output tricky stuff here just to rename the file to make it work nicely with the code already set up
change_task_input "DiCER"
sh /home/kaqu0001/HCPpipelines/Examples/Scripts/TaskfMRIAnalysisBatch.sh --runlocal
copying_task_results "DiCER"
# Here now resetting it so that it goes back to the standard input (important!! so that it doesn't screw up new runs!)
change_task_input "standard"

# STEP 4: do the same for GMR
change_task_input "GMR"
sh /home/kaqu0001/HCPpipelines/Examples/Scripts/TaskfMRIAnalysisBatch.sh --runlocal
copying_task_results "GMR"
change_task_input "standard"
