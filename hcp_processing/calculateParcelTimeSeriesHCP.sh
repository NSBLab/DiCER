#!/bin/env bash

#SBATCH --job-name=hcpParcelTS
#SBATCH --account=kg98
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=30:00
#SBATCH --mail-user=kevin.aquino@monash.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=16000
#SBATCH -A kg98
#SBATCH --qos=shortq
#SBATCH --array=1


SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon.txt"

export subject=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SUBJECT_LIST})
echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} ----- "
echo -e "\t\t\t --------------------------- \n"

#Load connectome module and matlab
module load connectome
module load matlab
working_hcp_dir=/scratch/kg98/HCP_grayordinates_processed/
hcpmatlabtools=/home/kaqu0001/projects/matlabHCPtools/
giftitoolbox=/home/kaqu0001/projects/gifti/

# First create a GMR variant of the time series
fileToRegress=$working_hcp_dir"/"$subject"/"$subject"_rest_dm.nii.gz"
gm_signal=$working_hcp_dir"/"$subject"/"$subject"_rest_GMsignal.txt"
GMR_output=$working_hcp_dir"/"$subject"/"$subject"_rest_dm_GMR.nii.gz"

# Peform the regression:
fsl_regfilt -i $fileToRegress -d $gm_signal -f 1 -o $GMR_output


template_cifti=$working_hcp_dir"/"$subject"/"$subject"_all_rest_Atlas_MSMAll.dtseries.nii"

# Now do the process of going back to CIFTI, then going to GIFTI. These are fairly large files, so once this is done, then they will be deleted

# A bash function to peform the analysis
parcel_time_series () {
	# First have to split up the regressor file
	preproType=$1
	fileTimeSeries=$working_hcp_dir"/"$subject"/"$subject"_rest_"$preproType".nii.gz"
	temp_cifti=$working_hcp_dir"/"$subject"/"$subject"_all_rest_Atlas_MSMAll"$preproType".dtseries.nii"
	temp_gifti=$working_hcp_dir"/"$subject"/"$subject"_all_rest_Atlas_MSMAll"$preproType".func.gii"
	# Convert the file to a cifti
	wb_command -cifti-convert -from-nifti $fileTimeSeries $template_cifti $temp_cifti
	# Convert the file to a gifti
	wb_command -cifti-convert -to-gifti-ext $temp_cifti $temp_gifti
	# Now remove the cifti
	rm -rf $temp_cifti
	# Run the matlab script
	output_tsv=$working_hcp_dir"/parcel_cortical_subcortical/"$preproType"/"$subject"_rest_"$preproType".tsv"
	matlab -nodisplay -r "addpath(genpath('${hcpmatlabtools}'));addpath(genpath('${giftitoolbox}'));create_parcel_series('${temp_gifti}','${output_tsv}'); exit"
	rm -rf $temp_gifti
}

# Run the parcel time series for each pipeline!
parcel_time_series "dm"
parcel_time_series "dm_GMR"
parcel_time_series "dm_dbscan"

