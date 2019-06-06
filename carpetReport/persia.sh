#!/bin/bash
# This is a bash script to go through many subjects, generate the plots then go into a bigger file,
# this will assume fmriprep directory structure.

# Set up initial parts:

# fmriprep_dir='/Users/kevinaquino/projects/GSR_data/UCLA_data_niftis/fmriprep/'
fmriprep_dir='/Users/kevinaquino/projects/GSR_data/testbed_fmriprep/'
space='MNI152NLin2009cAsym_variant'
func_labels='ICA-AROMA,DBSCAN'
# func_labels='ICA-AROMA'
ordering_labels='GS_ordering'
# Currently set up the html report in a different folder -- will change this soon
folder='/Users/kevinaquino/projects/GSR_data/testbed_fmriprep/dbscan/'

while IFS=$1 read -r line || [[ -n "$line" ]]; do
	subject=$line
	# ordering=$fmriprep_dir"/"$subject"/dbscan/"$subject'_T1w_space-'$space'_gm_mask_gsordering.nii.gz'
	ordering=$fmriprep_dir"/"$subject"/dbscan/"$subject'_T1w_space-'$space'_gm_mask_gsordering_tissue.nii.gz'
	mask=$fmriprep_dir"/"$subject"/dbscan/"$subject"_T1w_space-"$space"_gm_mask.nii.gz"
	func_list=$fmriprep_dir"/"$subject"/dbscan/"$subject"_task-rest_bold_space-"$space-"AROMAnonaggr+2P_preproc_detrended_hpf.nii.gz,"$fmriprep_dir"/"$subject"/dbscan/"$subject"_task-rest_bold_space-"$space-"AROMAnonaggr+2P_preproc_detrended_hpf_dbscan.nii.gz"
	dtissue=$fmriprep_dir"/"$subject"/dbscan/"$subject"_T1w_space-MNI152NLin2009cAsym_variant_dtissue_masked.nii.gz"	
	# echo $func_list
	# echo $ordering
	# echo $mask
	echo "processing ... "$subject
	python tapestry.py -f $func_list -fl $func_labels -m $mask -o $ordering -l $ordering_labels -s $subject -d $folder -ts $dtissue
done < "$1"

# Now after doing this, write up the combined report using bazaar.py
ordering_labels="random,"$ordering_labels
python bazaar.py -fl $func_labels -l $ordering_labels -sl $1 -d $folder


# $fmriprep_dir"/"$subject"/dbscan/"$subject"_task-rest_bold_space-"$space-"AROMAnonaggr+2P_preproc_detrended_hpf_dbscan.nii.gz"