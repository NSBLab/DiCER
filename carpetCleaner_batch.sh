space_variant='MNI152NLin2009cAsym'
FMRIPREP_DIR=$2
SCAN_ID=$3
# Note if you dont specify an ID this assumes nothing and makes it blank
module load anaconda/5.0.1-Python2.7-gcc5 
module load afni
module load fsl
# module load anaconda/5.0.1-Python3.6-gcc5
# will have to make it more general for func variants
if [ ! -d "$FMRIPREP_DIR/dbscan" ]; then
      mkdir -p $FMRIPREP_DIR/dbscan
fi
while IFS=$1 read -r line || [[ -n "$line" ]]; do
    #cd $FMRIPREP_DIR
    # Now look at the subject:
    subject=$line
	export FMRIPREP_DIR
	export space_variant
	export subject
	export SCAN_ID
	sbatch --job-name="$line" --output="./slurm_outputs/$line.out" carpetCleaner.sh
done < "$1"


# Should probably put the bazaar command in here as well.