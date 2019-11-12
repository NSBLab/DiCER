#!/bin/bash

# This file performs high pass filtering

func=$1
file_output=$2
folder_input=$3
mask_epi=$4

# ------------------------------ Temporal processing ------------------------------
# High pass filtering achieved via FSLMATHS -- note detrending has been taken out explicity, LPF might be enough

TemporalFilter=200
TR_line=$(fslinfo $func | grep pixdim4)
TR_vol=$(echo $TR_line |  cut -d " " -f 2)

echo "TR is set at:: " $TR_vol

hp_sigma=`echo "0.5 * $TemporalFilter / $TR_vol" | bc -l`;
# Use fslmaths to apply high pass filter and then add mean back to image

fslmaths $func -Tmean $folder_input/func_mean.nii.gz
fslmaths $func -bptf ${hp_sigma} -1 -add $folder_input/func_mean.nii.gz $file_output
# Convert "fake" NIFTI back to CIFTI




# Turn nans to zero (need to check this again later..)
fslmaths $file_output -nan $file_output
# ------------------------------ Temporal processing ------------------------------

# Remove the AFNI stuff
rm -rf $folder_input/prepro_func*