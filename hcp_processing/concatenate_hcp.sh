#! /bin/bash

# Here are all the tasks, and the order that they will be added in

task[0]='EMOTION'
task[1]='GAMBLING'
task[2]='LANGUAGE'
task[3]='MOTOR'
task[4]='RELATIONAL'
task[5]='SOCIAL'
task[6]='WM'

# Unzip them, then collect the time series
w_call=""


# this part of the loop gets all the tasks
for i in `seq 0 6`;
	do
		file=$subject"_3T_tfMRI_"${task[i]}"_preproc.zip"
		cp $hcp_storage"/"$file $temp_hcp_directory
		cd $temp_hcp_directory
		unzip $file
	        LR_file=$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_LR/tfMRI_"${task[i]}"_LR_Atlas_MSMAll.dtseries.nii"
	        RL_file=$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_RL/tfMRI_"${task[i]}"_RL_Atlas_MSMAll.dtseries.nii"
		# Now change to nifti, then concatenate -- working with GIFTIs would be better to be honest, but dw about it for now?
		cd $subject
		cp $LR_file ./
		cp $RL_file ./ 
		wb_call=$wb_call" -cifti tfMRI_"${task[i]}"_LR_Atlas_MSMAll.dtseries.nii -cifti tfMRI_"${task[i]}"_RL_Atlas_MSMAll.dtseries.nii"
		# remove on the fly
	done
echo "Combining all tasks CIFTIs into a single CIFTI"
wb_command -cifti-merge all_tasks_Atlas_MSMAll.dtseries.nii $wb_call

# Copy the all task file into the working hcp_directory for that task
if [ ! -d "$working_hcp_dir/$subject/" ]; then
          mkdir -p $working_hcp_dir/$subject/
fi

# Now copy the dtseries that you hae processed into the directory you are working in
cp $temp_hcp_directory/$subject/all_tasks_Atlas_MSMAll.dtseries.nii $working_hcp_dir"/"$subject"/"

echo "Copied the all_tasks CIFTI!"

