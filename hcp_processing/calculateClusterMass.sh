# !/bin/bash

# zMap=Group_50_emotion_tfMRI_EMOTION_level3_zstat1_hp200_s2_MSMAll.dscalar.nii
zMap=$1
tmp_dir=$2
textFile=$3

# echo $0
# echo $2
# echo $3

wb_command -cifti-find-clusters $zMap 5 5 5 5 COLUMN $2/cluster.dscalar.nii -left-surface ~/projects/matlabHCPtools/HCP_data_Glasser_2016/Q1-Q6_RelatedParcellation210.L.midthickness_MSMAll_2_d41_WRN_DeDrift.32k_fs_LR.surf.gii -right-surface ~/projects/matlabHCPtools/HCP_data_Glasser_2016/Q1-Q6_RelatedParcellation210.R.midthickness_MSMAll_2_d41_WRN_DeDrift.32k_fs_LR.surf.gii 
clusterMap=$2/cluster.dscalar.nii
vertexAreas=~/projects/matlabHCPtools/surfaceArea.dscalar.nii

wb_command -cifti-math '(x > 0)*y' $2/restrictedZmap.dscalar.nii -var x $clusterMap -var y $zMap

# Now seperate into left and right then combine
wb_command -cifti-separate $2/restrictedZmap.dscalar.nii COLUMN -metric CORTEX_LEFT $2/clust_left.func.gii
wb_command -cifti-separate $2/restrictedZmap.dscalar.nii COLUMN -metric CORTEX_RIGHT $2/clust_right.func.gii
# Combine it all up together
wb_command -cifti-create-dense-scalar $2/clust_all.dscalar.nii -left-metric $2/clust_left.func.gii -right-metric $2/clust_right.func.gii 

# Now do the operation to make it into one:
wb_command -cifti-math 'x*y' $2/zmapMassArea.dscalar.nii -var x $2/clust_all.dscalar.nii -var y $vertexAreas

# Port this to a file
wb_command -cifti-stats $2/zmapMassArea.dscalar.nii -reduce SUM > $textFile
