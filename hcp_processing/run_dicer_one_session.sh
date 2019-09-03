#!/bin/bash 

# Here take a task out, then 

# Set up wd for HCP data (where it needs to be saved)
export working_hcp_dir=/scratch/kg98/HCP_grayordinates_processed

# set up directory for where the temporary files get saved:
export temp_hcp_directory=/scratch/kg98/HCP_grayordinates_processed_temporary

# Run this for one session (set as an argument)
TASK=MOTOR
PEs[0]=LR
PEs[1]=RL

# # Set up a script to do both PEs
# for pd in `seq 0 1`;
# 	do
# 		PE=${PEs[pd]}
# 		# First copy the session file into the working_hcp_dir, run DiCER on that task (and then most likely run the task for that subject)
# 		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
# 		fMRI_nifti="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.nii.gz"
# 		wb_command -cifti-convert -to-nifti $temp_hcp_directory/$subject/$fMRI $working_hcp_dir/$subject/$fMRI_nifti

# 		# Run DiCER Lightweight
# 		sh DiCER_lightweight.sh -f -i $fMRI_nifti -w $working_hcp_dir/$subject/ -s $subject"_"$TASK"_"$PE -p 5

# 	done


# Run Task analysis for the standard
TaskNameList=""
export TaskNameList="${TaskNameList} $TASK"

sh TaskfMRIAnalysisBatch.sh 
# Then copy the files somewhere


for pd in `seq 0 1`;
	do
		PE=${PEs[pd]}
		# Now run this sequentially i think, no need to think about double versions as its done differently
		# Should have a file per denoising, no need to re-denoise just convert to CIFTI after each one has finished
		preproFile=
		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
		taskFolder=$temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_"${PEs[pd]}"/"

		original_cifti=$taskFolder"/"$fMRI
		reference_cifti=$temp_hcp_directory/$subject/$fMRI

		# Convert the file back to CIFTI format:
		wb_command -cifti-convert -from-nifti $preproFile $reference_cifti $original_cifti
	done

# Run Task analysis for the DiCER
sh TaskfMRIAnalysisBatch.sh 
# Then copy the files somewhere


# WB_command for GMR
for pd in `seq 0 1`;
	do
		PE=${PEs[pd]}
		# Now run this sequentially i think, no need to think about double versions as its done differently
		# Should have a file per denoising, no need to re-denoise just convert to CIFTI after each one has finished
		preproFile=
		fMRI="tfMRI_"$TASK"_"$PE"_Atlas_MSMAll.dtseries.nii"
		taskFolder=$temp_hcp_directory"/"$subject"/MNINonLinear/Results/tfMRI_"$TASK"_"${PEs[pd]}"/"

		original_cifti=$taskFolder"/"$fMRI
		reference_cifti=$temp_hcp_directory/$subject/$fMRI
		
		# Convert the file back to CIFTI format:
		wb_command -cifti-convert -from-nifti $preproFile $reference_cifti $original_cifti
	done

# Run Task analysis for GMR
sh TaskfMRIAnalysisBatch.sh 
# Then copy the files somewhere