#!/bin/bash

# Note you also have to add:
# SCAN_ID
# For different runs etc.
# This bash script file takes in something for one subject, run the prelim stuff to get it into DBSCAN territory, then after that run the vis stuff


# STAGE 1:
# ======================================================================
# Preliminary preprocessing:

# (will make the bottom a better function, it looks messy to be in here at the moment)

#SBATCH --account=kg98
#SBATCH --time=00:30:00
# SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=12000
#SBATCH --qos=shortq


# Here adjust it all.
prepro_variant=AROMAnonaggr
# Have to remember to always start without 2P then add 2P aggressively later, this is a reasonable thing to have to be honest. 
# Now here see if we use aggresive AROMA what happens to the overall structure of things does this change the qc-fc?

# prepro_variant=smoothAROMAnonaggr

echo "Processing " $subject ".................."
if [ ! -d "$FMRIPREP_DIR/$subject/dbscan" ]; then
          mkdir -p $FMRIPREP_DIR/$subject/dbscan
fi
# Remove existing stuff in dbscan
rm -rf $FMRIPREP_DIR/$subject/dbscan/*
# rm -rf $FMRIPREP_DIR/$subject/dbscan/*.txt

func=$FMRIPREP_DIR/$subject'/func/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc.nii.gz"
confounds=$FMRIPREP_DIR/$subject'/func/'$subject"_task-rest_"$SCAN_ID"bold_confounds.tsv"
gm_prob_T1w=$FMRIPREP_DIR/$subject/anat/$subject"_T1w_space-"$space_variant"_class-GM_probtissue.nii.gz"
gm_prob_epi=$FMRIPREP_DIR/$subject/anat/$subject"_bold_space-"$space_variant"_class-GM_probtissue.nii.gz"
mask_T1w=$FMRIPREP_DIR/$subject/anat/$subject"_T1w_space-"$space_variant"_brainmask.nii.gz"
mask_epi=$FMRIPREP_DIR/$subject/anat/$subject"_bold_space-"$space_variant"_brainmask.nii.gz"

dtissue_T1w=$FMRIPREP_DIR/$subject/anat/$subject"_T1w_space-"$space_variant"_dtissue.nii.gz"
dtissue_epi=$FMRIPREP_DIR/$subject/anat/$subject"_bold_space-"$space_variant"_dtissue.nii.gz"
dtissue_epi_masked=$FMRIPREP_DIR/$subject"/dbscan/"$subject"_bold_space-"$space_variant"_dtissue_masked.nii.gz"

#flirt the masks and maps to be in epi space
flirt -in $gm_prob_T1w -out $gm_prob_epi -ref $func -applyxfm -usesqform
flirt -in $mask_T1w -out $mask_epi -ref $func -applyxfm -usesqform
flirt -in $dtissue_T1w -out $dtissue_epi -ref $func -applyxfm -interp nearestneighbour -usesqform

# Have this mean epi for the purposes of using this for a mask later on
mean_epi_targ=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc_mean.nii.gz"

# Now take the tissue mask and explicity mask it off to where the mean $func image is > 0
fslmaths $func -Tmean $mean_epi_targ
fslmaths $dtissue_epi -mas $mean_epi_targ $dtissue_epi_masked

dbscan_folder=$FMRIPREP_DIR/$subject"/dbscan/"
gm_dbscan=$FMRIPREP_DIR/$subject"/dbscan/"$subject"_bold_space-"$space_variant"_gm_mask.nii.gz"
tissue_ordering=$FMRIPREP_DIR/$subject"/dbscan/"$subject"_bold_space-"$space_variant"_gm_mask_gsordering_tissue.nii.gz"

export func
export gm_prob_epi
export gm_dbscan
export mask_epi
export dtissue_epi_masked
export confounds
export dbscan_folder

# Below is what the inputs to dbscan end up looking like
# input_dbscan=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc_detrended_hpf.nii.gz"
# export input_dbscan

# In this section perform the 2P regression (WM and CSF)

# ------------------------------ Restrictive masks ------------------------------
# First make mask for gm probability
fslmaths $gm_prob_epi -thr 0.5 -bin $dbscan_folder/temp_mask_gm

# Now get a mean t-series
fslmaths $func -Tmean $dbscan_folder/temp_mask_30

# Now find the min/max
read min max <<< $(fslstats $dbscan_folder/temp_mask_30 -r)

# Normalize the image and threshold the map to make a mask of epi of the top 70% of image intensity
fslmaths $dbscan_folder/temp_mask_30 -div $max -thr 0.3 -bin $dbscan_folder/temp_mask_30

# Now finally at the end combine the masks
fslmaths $dbscan_folder/temp_mask_gm -mul $dbscan_folder/temp_mask_30 $gm_dbscan

# Now add this to the tissue masks, firstly make the binary mask equal to 2
fslmaths $gm_dbscan -mul 2 $dbscan_folder/temp_gm_2

# Now do an addition to make any overlapping masks here apparent, the voxels used in dbscan have index = 4, GM voxels NOT included in dscan = 3
fslmaths $dbscan_folder/temp_gm_2 -add $dtissue_epi_masked $dtissue_epi_masked


# Now generate the masks for CSF and WM
# Below is adapted from from Parkes et. al 2018 -> https://github.com/lindenmp/rs-fMRI 
gm=$subject"_T1w_space-"$space_variant"_class-GM_probtissue"
csf=$subject"_T1w_space-"$space_variant"_class-CSF_probtissue"
wm=$subject"_T1w_space-"$space_variant"_class-WM_probtissue"
bmask=$subject"_T1w_space-"$space_variant"_brainmask"

csf_epi=$subject"_bold_space-"$space_variant"_CSF"
wm_epi=$subject"_bold_space-"$space_variant"_WM"
csfwm_epi=$subject"_bold_space-"$space_variant"_CSFWM"

# Directories:
tmp_roi_dir=$FMRIPREP_DIR/$subject"/dbscan/tmp"
anat_dir=$FMRIPREP_DIR/$subject/anat/
# make a temp directory for these intermediate steps for ROI creation
mkdir -p $tmp_roi_dir


# threshold gm and binarise
fslmaths $anat_dir/$gm -thr 0.95 -bin $tmp_roi_dir/vmask

# Dilate the mask twice
fslmaths $tmp_roi_dir/vmask -dilD -bin $tmp_roi_dir/vmask
fslmaths $tmp_roi_dir/vmask -dilD -bin $tmp_roi_dir/vmask

# combined with wm and invert
fslmaths $tmp_roi_dir/vmask -add $anat_dir/$wm -binv $tmp_roi_dir/vmask

# erode whole brain mask twice
fslmaths $anat_dir/$bmask -eroF $tmp_roi_dir/e_native_t1_brain_mask
fslmaths $tmp_roi_dir/e_native_t1_brain_mask -eroF $tmp_roi_dir/e_native_t1_brain_mask

# multipy eroded brain mask with vmask
fslmaths $tmp_roi_dir/vmask -mul $tmp_roi_dir/e_native_t1_brain_mask $tmp_roi_dir/$csf"v"

# Now erode CSF twice
fslmaths $tmp_roi_dir/$csf"v" -eroF -bin $tmp_roi_dir/$csf"_e1"
fslmaths $tmp_roi_dir/$csf"_e1" -eroF -bin $tmp_roi_dir/$csf"_e2"

# CSF eroded mask complete

# WM mask generation

# mask out non-brain
fslmaths $anat_dir/$wm -thr 0.95 -bin $tmp_roi_dir/$wm"v"

input_wm=$tmp_roi_dir/$wm"v"
for i in `seq 1 5`;
	do
		output_wm=$tmp_roi_dir/$wm"_e"$i
		fslmaths $input_wm -eroF -bin $output_wm
		# Now save the input for the next erosion
		intput_wm=$output_wm
	done

# After this interpolate to epi space using nearest neighbor interpolation.
flirt -in $tmp_roi_dir/$csf"_e1" -ref $func -out $tmp_roi_dir/$csf_epi"_e1" -applyxfm -interp nearestneighbour -usesqform
flirt -in $tmp_roi_dir/$wm"_e5" -ref $func -out $tmp_roi_dir/$wm_epi"_e5" -applyxfm -interp nearestneighbour -usesqform

# Now combine both of these into one nifti, labelling wm as 2
fslmaths $tmp_roi_dir/$wm_epi"_e5" -mul 2 -add $tmp_roi_dir/$csf_epi"_e1" $FMRIPREP_DIR/$subject"/dbscan/"$csfwm_epi



# ------------------------------ Restrictive masks ------------------------------




#==== REGRESSION ===========
# 2P and GSR files
# I think for consistency to work straight out of fmriprep,
# I will have to start from the premise that we do not have the wm/csf stuff in there.

# Grabbing WM+CSF (2P) -- This has to be recalculated, need to get the ROIs and do what fMRIprep does for the ROIs of CSF and wm.
# awk -v OFS='\t' '{if(NR>1)print $1,$2}' $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_confounds.tsv > $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsf.tsv
# Replacement 2P:
fslmeants -i $func --label=$FMRIPREP_DIR/$subject"/dbscan/"$csfwm_epi -o $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsf.tsv


# Grabbing WM+CSF+GSR (2P+GSR)
# awk -v OFS='\t' '{if(NR>1)print $1,$2,$3}' $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_confounds.tsv > $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsfgs.tsv
# Replacement GSR 
fslmeants -i $func --label=$mask_epi -o $FMRIPREP_DIR/$subject'/dbscan/'$subject"_brain_signal.txt"
paste -d '\t' $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsf.tsv $FMRIPREP_DIR/$subject'/dbscan/'$subject"_brain_signal.txt" > $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsfgs.tsv


# Here grabbing GM signal (2P+GMR)
fslmeants -i $func --label=$dtissue_epi_masked -o $FMRIPREP_DIR/$subject'/dbscan/'$subject"_tissue_signals.txt"
awk -v OFS='\t' '{print $4}' $FMRIPREP_DIR/$subject'/dbscan/'$subject"_tissue_signals.txt" > $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_gm.tsv
paste -d '\t' $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsf.tsv $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_gm.tsv > $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsfgm.tsv


# Now perform the regression

func_2P=$FMRIPREP_DIR/$subject'/func/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P.nii.gz"
func_2P_GSR=$FMRIPREP_DIR/$subject'/func/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P+GSR.nii.gz"
func_2P_GMR=$FMRIPREP_DIR/$subject'/func/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P+GMR.nii.gz"

# WM+CSF (2P)
fsl_regfilt -i $func -d $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsf.tsv -f 1,2 -o $func_2P -a
# WM+CSF+GSR (2P+GSR)
fsl_regfilt -i $func -d $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsfgs.tsv -f 1,2,3 -o $func_2P_GSR -a
# WM+CSF+GMR (2P+GMR)
fsl_regfilt -i $func -d $FMRIPREP_DIR/$subject'/func/'${subject}_task-rest_bold_wmcsfgm.tsv -f 1,2,3 -o $func_2P_GMR -a

#  STAGE 1B: Perform high pass filtering
# ======================================================================
# First one: inputs for DBSCAN (AROMA+2P)
input_dbscan=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P_detrended_hpf.nii.gz"
sh fmriprepProcess/preprocess_fmriprep.sh $func_2P $input_dbscan $dbscan_folder $mask_epi
# Second one: AROMA+2P+GSR
func_2P_GSR_dhpf=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P+GSR_detrended_hpf.nii.gz"
sh fmriprepProcess/preprocess_fmriprep.sh $func_2P_GSR $func_2P_GSR_dhpf $dbscan_folder $mask_epi
# Third one: AROMA+2P+GMR
func_2P_GMR_dhpf=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P+GMR_detrended_hpf.nii.gz"
sh fmriprepProcess/preprocess_fmriprep.sh $func_2P_GMR $func_2P_GMR_dhpf $dbscan_folder $mask_epi
# UP TO HERE fix up this then propagate changes below. Also in future maybe see if we can get naming conventions w/o nii.gz so code is cleaner.


echo "up to reordering GS"
python --version
# Now run a python script to do the global signal reordering:
echo $input_dbscan
echo $dtissue_epi_masked
echo $tissue_ordering
python fmriprepProcess/gsReorder.py -f $input_dbscan -ts $dtissue_epi_masked -of $tissue_ordering
# matlab -r  "run('fmriprepProcess/create_mask_dbscan.m');exit" -nodisplay -nodesktop -nosplash


# STAGE 2:
# ======================================================================
# DBSCAN cluster correction to retreive the regressors

output_folder=$FMRIPREP_DIR/$subject'/dbscan/'

# mask_gm=sub-10448_T1w_space-MNI152NLin2009cAsym_variant_gm_mask.nii.gz
# mask_gm=$FMRIPREP_DIR/$subject"/dbscan/"$subject"_T1w_space-"$space_variant"_variant_gm_mask.nii.gz"
python carpetCleaning/clusterCorrect.py $dtissue_epi_masked '.' $input_dbscan $output_folder $subject

# STAGE 3:
# ======================================================================
# Regress out all the regressors
regressor_dbscan=$subject"_dbscan_liberal_regressors.csv"
# f1=$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc_detrended_hpf.nii.gz"
f1=$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P_detrended_hpf.nii.gz"
python carpetCleaning/vacuum_dbscan.py -f $f1 -db $regressor_dbscan -s $subject -d $output_folder

# Calculate aGMR
# regressor=$subject"_aGMR.csv"
# python carpetCleaning/vacuum_dbscan.py -f $f1 -db $regressor -s $subject -d $output_folder -of "aGMR"

output_dbscan=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc+2P_detrended_hpf_dbscan.nii.gz"
# output_aGMR=$FMRIPREP_DIR/$subject'/dbscan/'$subject"_task-rest_"$SCAN_ID"bold_space-"$space_variant"_variant-"$prepro_variant"_preproc_detrended_hpf_aGMR.nii.gz"

# STAGE 4:
# ======================================================================
# Run tapestry for this subject -- i.e. the carpet plot for this subject and run cluster reorder as well
# Firstly make sure that the renderer is in this format not requiring an X-server! :)
export MPLBACKEND="agg"
# Cluster reorder here....

# Do the cluster re-ordering:
python fmriprepProcess/clusterReorder.py $dtissue_epi_masked '.' $input_dbscan $output_folder $subject
cluster_tissue_ordering=$FMRIPREP_DIR/$subject/dbscan/$subject"_bold_space-"$space_variant"_dtissue_masked_clusterorder.nii.gz"

# Run the automated report:
python carpetReport/tapestry.py -f $input_dbscan","$output_dbscan","$func_2P_GMR_dhpf","$func_2P_GSR_dhpf -fl "ICA_AROMA,DBSCAN,GMR,GSR"  -o $tissue_ordering","$cluster_tissue_ordering -l "GS_reorder,CLUST" -s $subject -d $FMRIPREP_DIR"/dbscan/" -ts $dtissue_epi_masked -reg $FMRIPREP_DIR/$subject'/dbscan/'$regressor_dbscan -cf $confounds

