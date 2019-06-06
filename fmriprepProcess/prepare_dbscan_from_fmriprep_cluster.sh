space_variant='MNI152NLin2009cAsym'
FMRIPREP_DIR=$2
# will have to make it more general for func variants
while IFS=$1 read -r line || [[ -n "$line" ]]; do
        #cd $FMRIPREP_DIR
        # Now look at the subject:
        subject=$line
	export FMRIPREP_DIR
	export space_variant
	export subject
	sbatch --job-name="$line" --output="./slurm_outputs/$line.out" prepare_dbscan_from_fmriprep_cluster.script 
done < "$1"

