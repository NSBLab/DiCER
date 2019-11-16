# !/bin/bash
# 
# calculate_dvars.sh
# Taken from Thomas Nicols' paper on calculating DVARS
# 
# Here is a tool to calculate DVARS

# folder=/Users/kevinaquino/projects/HCP/100206
# Tmp=$folder/tmp
# tissueMask=$folder/tissue.nii.gz
# OUT=$folder/dvars.txt
# FUNC=$folder/100206_task_dm_dbscan.nii.gz
# 
FUNC=$1
Tmp=$2
tissueMask=$3
OUT=$4

# Find mean over time
fslmaths "$FUNC" -Tmean $Tmp-Mean

# Find the brain


# Compute robust estimate of standard deviation
fslmaths "$FUNC" -Tperc 25 $Tmp-lq
fslmaths "$FUNC" -Tperc 75 $Tmp-uq
fslmaths $Tmp-uq -sub $Tmp-lq -div 1.349 $Tmp-SD -odt float
# Compute (non-robust) estimate of lag-1 autocorrelation
fslmaths "$FUNC" -sub $Tmp-Mean -Tar1 $Tmp-AR1 -odt float
# Compute (predicted) standard deviation of temporal difference time series
fslmaths $Tmp-AR1 -mul -1 -add 1 -mul 2 -sqrt -mul $Tmp-SD  $Tmp-DiffSDhat
# Save mean value
DiffSDmean=$(fslstats $Tmp-DiffSDhat -k $tissueMask -M)
echo -n "."
# Compute temporal difference time series
nVol=$(fslnvols "$FUNC")
fslroi "$FUNC" $Tmp-FUNC0 0 $((nVol-1))
fslroi "$FUNC" $Tmp-FUNC1 1 $nVol
echo -n "."
# Compute DVARS, no standization
fslmaths $Tmp-FUNC0 -sub $Tmp-FUNC1                $Tmp-Diff -odt float
fslstats -t $Tmp-Diff       -k $tissueMask -S > $Tmp-DiffSD.dat
if [ "$AllVers" = "" ] ; then
    # Standardized
    awk '{printf("%g\n",$1/'"$DiffSDmean"')}' $Tmp-DiffSD.dat > "$OUT"
else
    # Compute DVARS, based on voxel-wise standardized image
    fslmaths $Tmp-FUNC0 -sub $Tmp-FUNC1 -div $Tmp-DiffSDhat $Tmp-DiffVxStdz
    fslstats -t $Tmp-DiffVxStdz -k $tissueMask -S > $Tmp-DiffVxStdzSD.dat
    # Sew it all together
    awk '{printf("%g\t%g\n",$1/'"$DiffSDmean"',$1)}' $Tmp-DiffSD.dat > $Tmp-DVARS
    paste $Tmp-DVARS $Tmp-DiffVxStdzSD.dat > "$OUT"
fi
