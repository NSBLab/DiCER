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
wb_call=""


# Copy the all task file into the working hcp_directory for that task, this is getting ready for it
if [ ! -d "$working_hcp_dir/$subject/" ]; then
          mkdir -p $working_hcp_dir/$subject/
fi

# make empty files to copy all the physio and all the movement files
touch $working_hcp_dir/$subject/$subject"_physio_task.txt"
touch $working_hcp_dir/$subject/$subject"_Movements_task.txt"
touch $working_hcp_dir/$subject/$subject"_Movements_regressors_task.txt"

# this part of the loop gets all the tasks
for i in `seq 0 6`;
	do
		file=$subject"_3T_tfMRI_"${task[i]}"_preproc.zip"
		cp $hcp_storage"/"$subject"/preproc/"$file $temp_hcp_directory
		cd $temp_hcp_directory
		unzip -o $file
	        LR_file=$temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_LR/tfMRI_"${task[i]}"_LR_Atlas_MSMAll.dtseries.nii"
	        RL_file=$temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_RL/tfMRI_"${task[i]}"_RL_Atlas_MSMAll.dtseries.nii"
		# Now change to nifti, then concatenate -- working with GIFTIs would be better to be honest, but dw about it for now?
		cd $subject
		cp $LR_file $temp_hcp_directory/$subject/
		cp $RL_file $temp_hcp_directory/$subject/
		wb_call=$wb_call" -cifti tfMRI_"${task[i]}"_LR_Atlas_MSMAll.dtseries.nii -cifti tfMRI_"${task[i]}"_RL_Atlas_MSMAll.dtseries.nii"
	
		# concatenate the physiological files:
		cat $working_hcp_dir/$subject/$subject"_physio_task.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_LR/tfMRI_"${task[i]}"_LR_Physio_log.txt" > $temp_hcp_directory/$subject/$subject"_physio_tmp.txt"
		cat $temp_hcp_directory/$subject/$subject"_physio_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_RL/tfMRI_"${task[i]}"_RL_Physio_log.txt" > $working_hcp_dir/$subject/$subject"_physio_task.txt"

		# concatenate the movement files:
		cat $working_hcp_dir/$subject/$subject"_Movements_task.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_LR/Movement_RelativeRMS.txt" > $temp_hcp_directory/$subject/$subject"_Movements_tmp.txt" 
		cat $temp_hcp_directory/$subject/$subject"_Movements_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_RL/Movement_RelativeRMS.txt" > $working_hcp_dir/$subject/$subject"_Movements_task.txt"

                # concatenate the movement regressor files:
                cat $working_hcp_dir/$subject/$subject"_Movements_regressors_task.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_LR/Movement_Regressors.txt" > $temp_hcp_directory/$subject/$subject"_Movements_tmp.txt"
                cat $temp_hcp_directory/$subject/$subject"_Movements_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/tfMRI_"${task[i]}"_RL/Movement_Regressors.txt" > $working_hcp_dir/$subject/$subject"_Movements_regressors_task.txt"
		# remove on the fly
	done

cd $temp_hcp_directory/$subject
echo "Combining all tasks CIFTIs into a single CIFTI"
wb_command -cifti-merge $subject"_all_tasks_Atlas_MSMAll.dtseries.nii" $wb_call


# Now copy the dtseries that you hae processed into the directory you are working in
cp $temp_hcp_directory/$subject/$subject"_all_tasks_Atlas_MSMAll.dtseries.nii" $working_hcp_dir"/"$subject"/"

echo "Copied the all_tasks CIFTI!"
echo "deleting all task zip files for $subject ... "
# Have to delete to avoid space issues
rm -rf $subject*.zip

# Now for resting state fMRI files, need to have the same set up

# make empty files to copy all the physio and all the movement files
touch $working_hcp_dir/$subject/$subject"_physio_rest.txt"
touch $working_hcp_dir/$subject/$subject"_Movements_rest.txt"
touch $working_hcp_dir/$subject/$subject"_Movements_regressors_rest.txt"

# Here we get all the rest files and do so for both sessions, session 1 and 2, this concatenation is looking for respones respent all throughout
wb_call=""
file=$subject"_3T_rfMRI_REST_fix.zip"
cp $hcp_storage"/"$subject"/fix/"$file $temp_hcp_directory
cd $temp_hcp_directory
unzip -o $file
for i in `seq 1 2`; 
	do
                LR_file=$temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_LR/rfMRI_REST"$i"_LR_Atlas_MSMAll_hp2000_clean.dtseries.nii"
                RL_file=$temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_RL/rfMRI_REST"$i"_RL_Atlas_MSMAll_hp2000_clean.dtseries.nii"
                # Now change to nifti, then concatenate -- working with GIFTIs would be better to be honest, but dw about it for now?
                cp $LR_file $temp_hcp_directory/$subject/
                cp $RL_file $temp_hcp_directory/$subject/
                wb_call=$wb_call" -cifti rfMRI_REST"$i"_LR_Atlas_MSMAll_hp2000_clean.dtseries.nii -cifti rfMRI_REST"$i"_RL_Atlas_MSMAll_hp2000_clean.dtseries.nii"

		#now comes the extra painful bit -- have to unzip preproc files - these should be deleted immediately after they are not used at all (well all of it really in the end)
		cp $hcp_storage/$subject/preproc/$subject"_3T_rfMRI_REST"$i"_preproc.zip" $temp_hcp_directory
		unzip -o $subject"_3T_rfMRI_REST"$i"_preproc.zip"		
                # concatenate the physiological files:
		cat $working_hcp_dir/$subject/$subject"_physio_rest.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_LR/rfMRI_REST"$i"_LR_Physio_log.txt" > $temp_hcp_directory/$subject/$subject"_physio_rest_tmp.txt"
		cat $temp_hcp_directory/$subject/$subject"_physio_rest_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_RL/rfMRI_REST"$i"_RL_Physio_log.txt" > $working_hcp_dir/$subject/$subject"_physio_rest.txt"

                # concatenate the movement files:
                cat $working_hcp_dir/$subject/$subject"_Movements_rest.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_LR/Movement_RelativeRMS.txt" > $temp_hcp_directory/$subject/$subject"_Movements_rest_tmp.txt"
		cat $temp_hcp_directory/$subject/$subject"_Movements_rest_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_RL/Movement_RelativeRMS.txt" > $working_hcp_dir/$subject/$subject"_Movements_rest.txt"

                # concatenate the movement files:
                cat $working_hcp_dir/$subject/$subject"_Movements_regressors_rest.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_LR/Movement_Regressors.txt" > $temp_hcp_directory/$subject/$subject"_Movements_rest_tmp.txt"
                cat $temp_hcp_directory/$subject/$subject"_Movements_rest_tmp.txt" $temp_hcp_directory/$subject"/MNINonLinear/Results/rfMRI_REST"$i"_RL/Movement_Regressors.txt" > $working_hcp_dir/$subject/$subject"_Movements_regressors_rest.txt"
	done
# remove on the fly

cd $temp_hcp_directory/$subject
echo "Combining all rest CIFTIs into a single CIFTI"
wb_command -cifti-merge $subject"_all_rest_Atlas_MSMAll.dtseries.nii" $wb_call


# Now copy the dtseries that you hae processed into the directory you are working in
cp $temp_hcp_directory/$subject/$subject"_all_rest_Atlas_MSMAll.dtseries.nii" $working_hcp_dir"/"$subject"/"
rm -rf $subject*.zip

# remove a bulk of the restfmri stuff because its not used elsewhere
cd $temp_hcp_directory/$subject/MNINonLinear/Results/
rm -rf rfMRI_REST*
cd $temp_hcp_directory/$subject/T1w/Results/
rm -rf rfMRI_REST*

# Last step copy and unzip all the preproc structural data
cd $temp_hcp_directory
file=$subject"_3T_Structural_preproc.zip"
cp $hcp_storage"/"$subject"/preproc/"$file $temp_hcp_directory
unzip -o $file

echo "Done the massive job of concatenation, unzipping etc, after you have finished, there is a seperate command to remove the tasks stuff that is not needed"
echo " "
echo " "
echo " Subject "$subject" is stored in "$temp_hcp_directory
