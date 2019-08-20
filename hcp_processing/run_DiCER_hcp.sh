#!/bin/env bash

#SBATCH --job-name=DiCER
#SBATCH --account=kg98
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=600:00
#SBATCH --mail-user=kevin.aquino@monash.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=32000
#SBATCH -A kg98
#SBATCH --array=1-100


SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon.txt"

export subject=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SUBJECT_LIST})
echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} ----- "
echo -e "\t\t\t --------------------------- \n"

#Load connectome module
module load connectome
module load anaconda/5.0.1-Python2.7-gcc5

DiCER_path=/home/kaqu0001/projects/DiCER/

cd $DiCER_path

# Set up wd for HCP data (where it needs to be saved)
export working_hcp_dir=/scratch/kg98/HCP_grayordinates_processed

# set up directory for where the temporary files get saved:
export temp_hcp_directory=/scratch/kg98/HCP_grayordinates_processed_temporary

# Where is the hcp dataset stored (it gets copied into the above)
export hcp_storage=/scratch/hcp1200/

# This file here concatenates all of the tasks together and all of the rsfMRI together
sh hcp_processing/concatenate_hcp.sh

echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} Concatention done, DiCER begins now----- "
echo -e "\t\t\t --------------------------- \n"


# ON REST:
wb_command -cifti-convert -to-nifti $working_hcp_dir/$subject/$subject"_all_rest_Atlas_MSMAll.dtseries.nii" $working_hcp_dir/$subject/$subject"_rest.nii.gz"
# Filter out session effects (its easy to see really)
fsl_regfilt -i $working_hcp_dir/$subject/$subject"_rest.nii.gz" -d ~/projects/DiCER/hcp_processing/restStopPoints.tsv -f 1,2,3,4 -o $working_hcp_dir/$subject/$subject"_rest_dm.nii.gz"
# Perform DiCER on the resting state:
sh DiCER_lightweight.sh -f -i $subject"_rest_dm.nii.gz"  -w $working_hcp_dir/$subject/ -s $subject"_rest" -p 5

# ON TASK:

wb_command -cifti-convert -to-nifti $working_hcp_dir/$subject/$subject"_all_tasks_Atlas_MSMAll.dtseries.nii" $working_hcp_dir/$subject/$subject"_task.nii.gz"
# Filter out session effects (its easy to see really)
fsl_regfilt -i $working_hcp_dir/$subject/$subject"_task.nii.gz" -d ~/projects/DiCER/hcp_processing/taskStopPoints.tsv -f 1,2,3,4,5,6,7,8,9,10,11,12,13,14 -o $working_hcp_dir/$subject/$subject"_task_dm.nii.gz"
# Perform DiCER on the task data:
sh DiCER_lightweight.sh -f -i $subject"_task_dm.nii.gz"  -w $working_hcp_dir/$subject/ -s $subject"_task" -p 5


echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} DiCER Finished - enjoy!----- "
echo -e "\t\t\t --------------------------- \n"
