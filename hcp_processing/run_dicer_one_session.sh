#!/bin/bash 
# SBATCH --job-name=${subject}_${TASK}
#SBATCH --account=kg98
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=600:00
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=32000
#SBATCH -A hf49

#SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon.txt"
#SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/WHITE1andWHITE2_remaining.txt"




module load anaconda/5.0.1-Python2.7-gcc5
module load connectome

# Here take a task out, then 

# Set up wd for HCP data (where it needs to be saved)
export working_hcp_dir=/scratch/kg98/HCP_grayordinates_processed

# set up directory for where the temporary files get saved:
export temp_hcp_directory=/scratch/kg98/HCP_grayordinates_processed_temporary

DICER_PATH=~/projects/DiCER/
# Run this for one session (set as an argument)
#TASK=MOTOR
PEs[0]=LR
PEs[1]=RL
cd $DICER_PATH
# Set up a script to do both PEs
for pd in `seq 0 1`;
 	do
 		PE=${PEs[pd]}
 		# First copy the session file into the working_hcp_dir, run DiCER on that task (and then most likely run the task for that subject)
 		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
 		fMRI_nifti="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.nii.gz"
		if [ ! -d $working_hcp_dir"/"$subject"/$TASK"_"$PE/" ]; then
                        mkdir -p $working_hcp_dir"/"$subject"/"$TASK"_"$PE"/"
		fi
 		wb_command -cifti-convert -to-nifti $temp_hcp_directory/$subject/$fMRI $working_hcp_dir/$subject"/"$TASK"_"$PE"/"$fMRI_nifti

 		# Run DiCER Lightweight
 		sh $DICER_PATH/DiCER_lightweight.sh -f -i $fMRI_nifti -w $working_hcp_dir/$subject"/"$TASK"_"$PE"/" -s $subject"_"$TASK"_"$PE -p 5 

 	done

cd $DICER_PATH/hcp_processing
# Additional stuff for task analysis to run.
export Subjlist=$subject
export StudyFolder=/scratch/kg98/HCP_grayordinates_processed_temporary/


# Run Task analysis for the standard
TaskNameList=""
export TaskNameList="${TaskNameList} $TASK"

# This is to make sure that if this is re-run, we make the conversion again to ensure it is really using the orignal CIFTI
for pd in `seq 0 1`;
        do
                PE=${PEs[pd]}
                # Now run this sequentially i think, no need to think about double versions as its done differently
                # Should have a file per denoising, no need to re-denoise just convert to CIFTI after each one has finished
                preproFile=$working_hcp_dir"/"$subject"/"$TASK"_"$PE"/tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.nii.gz"
                fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
                taskFolder=$temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_"${PEs[pd]}"/"

                original_cifti=$taskFolder"/"$fMRI
                reference_cifti=$temp_hcp_directory/$subject/$fMRI

                # Convert the file back to CIFTI format:
                wb_command -cifti-convert -from-nifti $preproFile $reference_cifti $original_cifti
        done



sh TaskfMRIAnalysisBatch.sh --runlocal
# Then copy the files somewhere (need to write a command for it, also need to see what to copy etc.)

# %copy the PE RL and LR into a folder
if [ ! -d $working_hcp_dir"/"$subject"/STANDARD_taskResults" ]; then
			mkdir -p $working_hcp_dir"/"$subject"/STANDARD_taskResults"
fi	
STANDARD_FOLDER=$working_hcp_dir"/"$subject"/STANDARD_taskResults"
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_LR/tfMRI_"$TASK"_LR_hp200_s2_level1_MSMAll.feat" $STANDARD_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_RL/tfMRI_"$TASK"_RL_hp200_s2_level1_MSMAll.feat" $STANDARD_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"/tfMRI_"$TASK"_hp200_s2_level2_MSMAll.feat" $STANDARD_FOLDER/



for pd in `seq 0 1`;
	do
		PE=${PEs[pd]}
		# Now run this sequentially i think, no need to think about double versions as its done differently
		# Should have a file per denoising, no need to re-denoise just convert to CIFTI after each one has finished
		preproFile=$working_hcp_dir"/"$subject"/"$TASK"_"$PE"/tfMRI_"$TASK"_"$PE"_Atlas_MSMAll_dbscan.nii.gz"
		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
		taskFolder=$temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_"${PEs[pd]}"/"

		original_cifti=$taskFolder"/"$fMRI
		reference_cifti=$temp_hcp_directory/$subject/$fMRI

		# Convert the file back to CIFTI format:
		wb_command -cifti-convert -from-nifti $preproFile $reference_cifti $original_cifti
	done

# Run Task analysis for the DiCER
sh TaskfMRIAnalysisBatch.sh --runlocal
# Then copy the files somewhere

# %copy the PE RL and LR into a folder
if [ ! -d $working_hcp_dir"/"$subject"/DICER_taskResults" ]; then
			mkdir -p $working_hcp_dir"/"$subject"/DICER_taskResults"
fi	
DICER_FOLDER=$working_hcp_dir"/"$subject"/DICER_taskResults"
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_LR/tfMRI_"$TASK"_LR_hp200_s2_level1_MSMAll.feat" $DICER_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_RL/tfMRI_"$TASK"_RL_hp200_s2_level1_MSMAll.feat" $DICER_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"/tfMRI_"$TASK"_hp200_s2_level2_MSMAll.feat" $DICER_FOLDER/



# WB_command for GMR
for pd in `seq 0 1`;
	do
		PE=${PEs[pd]}
		# Now run this sequentially i think, no need to think about double versions as its done differently
		# Should have a file per denoising, no need to re-denoise just convert to CIFTI after each one has finished		

		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
		fMRI_nifti="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.nii.gz"
		taskFolder=$temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_"${PEs[pd]}"/"

		original_cifti=$taskFolder"/"$fMRI
		reference_cifti=$temp_hcp_directory/$subject/$fMRI
		
		# Do regression of GMR
		regressor=$working_hcp_dir"/"$subject"/"$TASK"_"$PE"/"$subject"_"$TASK"_"${PEs[pd]}"_GMsignal.txt"
		preproFile=$working_hcp_dir"/"$subject"/"$TASK"_"$PE"/tfMRI_"$TASK"_"$PE"_Atlas_MSMAll_GMR.nii.gz"
		fsl_regfilt -i $working_hcp_dir"/"$subject"/"$TASK"_"$PE"/"$fMRI_nifti -d $regressor -o $preproFile -f 1
		
		# Convert the file back to CIFTI format:
		wb_command -cifti-convert -from-nifti $preproFile $reference_cifti $original_cifti
	done

# Run Task analysis for GMR
sh TaskfMRIAnalysisBatch.sh --runlocal
# Then copy the files somewhere

# %copy the PE RL and LR into a folder
if [ ! -d $working_hcp_dir"/"$subject"/GMR_taskResults" ]; then
			mkdir -p $working_hcp_dir"/"$subject"/GMR_taskResults"
fi	
GMR_FOLDER=$working_hcp_dir"/"$subject"/GMR_taskResults"
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_LR/tfMRI_"$TASK"_LR_hp200_s2_level1_MSMAll.feat" $GMR_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_RL/tfMRI_"$TASK"_RL_hp200_s2_level1_MSMAll.feat" $GMR_FOLDER/
cp -r $temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"/tfMRI_"$TASK"_hp200_s2_level2_MSMAll.feat" $GMR_FOLDER/

