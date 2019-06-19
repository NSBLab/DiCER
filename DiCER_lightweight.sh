#!/bin/bash

# This here is a lightweight version of DiCER, this does not assume you have run fmriprep, it just takes your own preprocessing, 
# and then applies DiCER to the result.

# This does require some inputs though:
# These inputs are needed all to make the report and to perform DiCER

input_file=$1			# The input file name (dont include the path, make sure its in the directory with everything else)
tissue=$2 				# The tissue file, 1=CSF,2=WM,3=GM (left over parts), 4=restricted GM. SAME dimensions as the first file
output_folder=$3		# Folder for all the inputs and outputs, all files relative to this
subject=$4				# The subject id, for saving files
confounds=$5			# A file that has all the confounds in it, currently set up like fmriprep, but can be made more general later

# Setting up extra variables:
folder=$output_folder #this is the working directory.
input=$output_folder$input_file
tissue_mask=$output_folder$tissue
confounds=$output_folder$confounds

python carpetCleaning/clusterCorrect.py $tissue_mask '.' $input $folder $subject

# Regress out all the regressors
regressor_dbscan=$subject"_dbscan_liberal_regressors.csv"
python carpetCleaning/vacuum_dbscan.py -f $input_file -db $regressor_dbscan -s $subject -d $folder

# Next stage: do the reporting, all done through "tapestry"
base_dicer_o=`basename $input .nii.gz`
dicer_output=$output_folder$base_dicer_o"_dbscan.nii.gz"

export MPLBACKEND="agg"

# Do the cluster re-ordering:
python fmriprepProcess/clusterReorder.py $tissue_mask '.' $input $folder $subject
cluster_tissue_ordering=$output_folder$base_dicer_o"_clusterorder.nii.gz"

# Run the automated report:
python carpetReport/tapestry.py -f $input","$dicer_output -fl "INPUT,DICER"  -o $cluster_tissue_ordering -l "CLUST" -s $subject -d $output_folder -ts $tissue_mask -reg $output_folder$regressor_dbscan -cf $confounds


