#!/bin/bash
#
# This is a bash file that takes a fmriprep output then prepares the data for fmriprep
#
# fmriprep_derivatives_directory, and list of subjects are the only two inputs
# file loads like:
# sh prepare_dbscan_from_fmriprep.sh $SUBJECT_LIST $FMRIPREP_DIR 

# change directory to the fmriprep dir
space_variant='MNI152NLin2009cAsym'
FMRIPREP_DIR=$2
# will have to make it more general for func variants
while IFS=$1 read -r line || [[ -n "$line" ]]; do	
	subject=$line
	export FMRIPREP_DIR
	export subject
	export space_variant
	sh prepare_dbscan_from_fmriprep_cluster.script
done < "$1" 
