#!/bin/bash

# This here is a lightweight version of DiCER, this does not assume you have run fmriprep, it just takes your own preprocessing, 
# and then applies DiCER to the result.

# This does require some inputs though:
# These inputs are needed all to make the report and to perform DiCER


print_usage() {
  printf "DiCER_lightweight\n
This tool performs (Di)ffuse (C)luster (E)stimation and (R)egression on data without fmriprep preprocessing. Here, we take fmri data that has NOT been detrended or demeaned (important!) and either a tissue tissue 
classification which is a file that has the same dimensions as the functional image with the following labels: 1=CSF,2=GM,3=WM,4=Restricted GM this restricted GM just takes the GM mask and takes the top 70 percent 
of signals (i.e. top 70 relative to the mean) to estimate noisy signals.\n
Usage with tissue map: DiCER_lightweight.sh -i input_nifti -t tissue_file -w output_folder -s subjectID -c confounds.tsv\n\n
Usage without tissue map: DiCER_lightweight.sh -i input_nifti -a T1w -w output_folder -s subjectID -c confounds.tsv\n\n
Optional (and recommonded) flag is -d, this detrends and high-pass filters the data. This allows better estimation of regressors, and is a very light cleaning of your data.\n
Optional (may be needed for high-res data) flag -p ds_factor (e.g. -p 3), this enforces a sparse-sampling of the tissue mask based on the global signal correlation, this needed for high res data to be tractable. \n
\n
\n
SURFACE fMRI DATA\n
If you happen to have surface-registered data with freesurfer (or equivalent) this can work by the following\n
DiCER_lightweight.sh -f -i input_nifti -w output_folder -s subjectID -p 6\n\n
Note, the surface file here will be in a nifti format (you can change this with tools like mri_convert etc) in the standard \n
type of of input that freesurfer uses for FS-FAST. Also downsampling is needed, -p 6 is recommened for data on things such as fsaverage \n
Kevin Aquino. 2019, email: kevin.aquino@monash.edu\n\n\nDiCER website: https://github.com/BMHLab/DiCER \n\n"

}

tissue=""
detrend="false"
makeTissueMap="false"
use_confounds="false"
ds_factor="0"
freesurfer="false"

# Everything will be in g-zipped niftis
FSLOUTPUTTYPE=NIFTI_GZ

# Have to make options if you need to generate a tissue file do so i.e. only if you specifiy the tissue file
while getopts 'i:t:a:w:s:c:dp:fh' flag; do
  case "${flag}" in
    i)  input_file="${OPTARG}" ;;  
    t)  tissue="${OPTARG}" ;;  
	a)  anatomical="${OPTARG}" 
		makeTissueMap="true";;  
    w) 	output_folder="${OPTARG}" ;;    
	s)  subject="${OPTARG}" ;;  
	c) 	confounds="${OPTARG}" 
		use_confounds="true";;  
	d) 	detrend="true" ;;  
	p)  ds_factor="${OPTARG}";;
	f) 	freesurfer="true" ;;
	h) print_usage 
		exit 1;;
    *) print_usage
       exit 1 ;;
  esac
done

# Make a temporary folder if it doesnt exist for all the segmentation and errata outputs
if [ ! -d "$output_folder/tmp_dir/" ]; then
          mkdir -p $output_folder/tmp_dir/
fi



# Setting up extra variables once you have everything!
folder=$output_folder #this is the working directory.
input=$output_folder"/"$input_file
confounds=$output_folder$confounds


# Surface niftis!
if $freesurfer;then
	# Change the dimensions of the nifti to make it work with the rest of the script, currently doesn't handle giftis or ciftis directly, making this shortcut to have the code work all the way through
	outFile=$output_folder"/func_temp.nii.gz"
	python hcp_processing/reshapeSurfaceNifti.py -f $input -o $outFile
	input=$outFile
	orig=$input_file
	input_file="func_temp.nii.gz"
	# Here just making a tissue file based just on the surface time series, i.e. setting it that all time series on the vertices are used in the estimation of regressors.
	fslmaths $input -Tmean -abs -bin -mul 4 $output_folder"tissue.nii.gz"
	tissue="tissue.nii.gz"
	# Here just making sure that the tissue map isn't made.
	makeTissueMap="false"	
	# will probably have to re-arrange the nifti -- then at the end of the whole shebang will have to re-sort.
fi

tissue_mask=$output_folder"/"$tissue


# Make the tissue map if you have specificed the tissue map!
# 
# TISSUE SEGMENTATION!
# 
if $makeTissueMap;then
	printf "\n\nPeforming FAST tissue segmentation with anatomical image $anatomical\n"
	# Perform FAST segmentation:
	fast -o $output_folder"/tmp_dir/"$subject $output_folder"/"$anatomical

	# Get the segmentation file:
	segmentation_file=$output_folder"/tmp_dir/"$subject"_seg"

	# Now apply the flirt command to get the segmentation into the func space:
	seg_temp=$output_folder"/tmp_dir/"$subject"_seg_temp"
	flirt -in $segmentation_file -ref $input -out $seg_temp -applyxfm -interp nearestneighbour -usesqform

	# Now using the standard convention in FAST we generate the tissue types
	# GM - be a little more conservative above what FAST gives out in its hard segmentation:
	flirt -in $output_folder"/tmp_dir/"$subject"_pve_1.nii.gz" -out $output_folder"/tmp_dir/"$subject"_ds_gm.nii.gz" -ref $input -applyxfm -usesqform
	gm_mask_tmp=$output_folder"/tmp_dir/"$subject"_gm_mask"
	fslmaths $output_folder"/tmp_dir/"$subject"_ds_gm.nii.gz" -thr 0.5 -bin $gm_mask_tmp	
	# Use the probability mask and threshold that one
	# fslmaths $seg_temp -thr 2 -uthr 2 -bin $gm_mask_tmp

	# Generate masks for GM to make it more restrictive:
	mean_ts=$output_folder"/tmp_dir/"$subject"_mean_ts"
	fslmaths $input -Tmean $mean_ts
	# Taking the mean ts image, and just focusing in on grey matter
	fslmaths $mean_ts -mul $gm_mask_tmp $mean_ts

	# Now find the min/max
	read min max <<< $(fslstats $mean_ts -r)

	# Normalize the image and threshold the map to make a mask of epi of the top 60% of image intensity
	gm_mask_restrictive=$output_folder"/tmp_dir/"$subject"_mask_restrictive"
	fslmaths $mean_ts -div $max -thr 0.3 -bin $gm_mask_restrictive
	fslmaths $gm_mask_restrictive -mul $gm_mask_tmp -mul 2 $gm_mask_restrictive

	# Now we have everything to work with and combine it all together now (fix up too many volumes)
	tissue_mask=$output_folder"/"$subject"_dtissue_func.nii.gz"
	fslmaths $seg_temp -add $gm_mask_restrictive $tissue_mask

	printf "\n\nSaved tissue mask in functional space and saved as: $tissue_mask\n"	
fi

#  Detrending and high-pass filtering data::
if $detrend;then
	printf "\n\Detrending and high-pass filtering $input..\n\n\n"		
	base_input=`basename $input .nii.gz`
	output_detrended=$output_folder"/"$base_input"_detrended_hpf.nii.gz"
	# Find a mask epi
	mask_epi=$output_folder"/tmp_dir/"$subject"_mask_epi.nii.gz"
	fslmaths $tissue_mask -bin $mask_epi
	sh fmriprepProcess/preprocess_fmriprep.sh $input $output_detrended $output_folder $mask_epi
	# Now change all the inputs to work on the deterended versions	
	input=$output_detrended
	input_file=$base_input"_detrended_hpf.nii.gz"
fi

if [ $ds_factor -gt 0 ];then
	printf "\n Creating a sparse-sampling of the tissue mask based on the correlation to the global signal for each voxel.\n"
	echo $input
	echo $tissue_mask
	echo $output_folder"/tmp_dir/"$subject"gsReorder.nii.gz"
	echo ""
	python fmriprepProcess/gsReorder.py -f $input -ts $tissue_mask -of $output_folder"/tmp_dir/"$subject"gsReorder.nii.gz"
	base_tissue_mask=`basename $tissue_mask .nii.gz` 
	tissue_mask_ds=$output_folder"/"$base_tissue_mask"_dsFactor_"$ds_factor".nii.gz"
	python utils/sparse_sample_tissue.py -o $output_folder"/tmp_dir/"$subject"gsReorder.nii.gz" -ds $ds_factor -ts $tissue_mask -tsd $tissue_mask_ds
	tissue_mask=$tissue_mask_ds
fi

printf "\n\nPerfoming DiCER..\n\n\n"	

python carpetCleaning/clusterCorrect.py $tissue_mask '.' $input $folder $subject

# Regress out all the regressors
regressor_dbscan=$subject"_dbscan_liberal_regressors.csv"


base_dicer_o=`basename $input .nii.gz`
dicer_output=$output_folder"/"$base_dicer_o"_dbscan.nii.gz"

printf "\n\nRegressing $input with DiCER signals and clean output is at $dicer_output \n\n\n"	
python carpetCleaning/vacuum_dbscan.py -f $input_file -db $regressor_dbscan -s $subject -d $folder"/"

# Next stage: do the reporting, all done through "tapestry"


export MPLBACKEND="agg"

# Do the cluster re-ordering:
printf "\n\nPeforming Cluster re-ordering of $input \n\n\n"	
python fmriprepProcess/clusterReorder.py $tissue_mask '.' $input $folder $subject
# if $freesurfer;then
# 	cluster_tissue_ordering=$output_folder"/tmp_dir/"$base_dicer_o"_clusterorder.nii.gz"	
# else
cluster_tissue_ordering=$output_folder"/"$base_dicer_o"_clusterorder.nii.gz"	
# fi

printf "\n\nPeforming GS re-ordering of $input (again use the mask) \n\n\n"	
python fmriprepProcess/gsReorder.py -f $input -ts $tissue_mask -of $output_folder"/"$subject_"gsReorder.nii.gz"
gs_reordering_file=$output_folder"/"$subject_"gsReorder.nii.gz"


printf "\n\nPeforming GMR of $orig \n\n\n"	
gm_signal=$output_folder"/"$subject"_GMsignal.txt"
fslmeants -i $input -o $gm_signal
GMR_output=$output_folder"/"$base_dicer_o"_GMR.nii.gz"
fsl_regfilt -i $input -d $gm_signal -f 1 -o $GMR_output


# Run the automated report:
printf "\n\nRunning the carpet reports! This is to visualize the data in a way to evaluate the corrections \n\n\n"	




# Here is a way to use confounds in the report, if they are not called then they will NOT appear in the automated report
if $use_confounds;then
	python carpetReport/tapestry.py -f $input","$GMR_output","$dicer_output -fl "INPUT,GMR,DICER"  -o $cluster_tissue_ordering,$gs_reordering_file -l "CLUST,GSO" -s $subject -d $output_folder"/" -ts $tissue_mask -reg $output_folder"/"$regressor_dbscan -cf $confounds
else
	python carpetReport/tapestry.py -f $input","$GMR_output","$dicer_output -fl "INPUT,GMR,DICER"  -o $cluster_tissue_ordering,$gs_reordering_file -l "CLUST,GSO" -s $subject -d $output_folder"/" -ts $tissue_mask
fi

# Have to at the end work with vacuuming the original file


# Surface niftis!
if $freesurfer;then
	printf "\n\n Now using the regression time series and regressing them from the original input \n\n\n"	
	input=$output_folder"/"$input_file
	python carpetCleaning/vacuum_dbscan.py -f $orig -db $regressor_dbscan -s $subject -d $folder"/"	
fi
