# Kevin Aquino
# Brain and Mental Health Research Hub
# 2018
#
# This is a python script to generate a carpet plot from given argeuments.

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning) 

# Import the right things.
import sys
import os
import numpy as np
from scipy import stats

# Import the little fmri_tools we need
sys.path.insert(1, os.path.join(sys.path[0], '..'))
from utils import fMRI_in_out as mrutils

# Take a signal, then reorder using this. 


def main(raw_args=None):

	# tissue,mask_voxels,time_series):
		
	# Parse in inputs
	from argparse import ArgumentParser
	parser = ArgumentParser(epilog="gsReorder.py -- A function to generate a list of reordering indices for each tissue type. Kevin Aquino 2018 BMH")
	parser.add_argument("-f", dest="func",
		help="functional MRI time series", metavar="fMRI")
	parser.add_argument("-ts", dest="dtissue",
		help="tisue segmentation", metavar="dtissue.nii.gz")
	parser.add_argument("-of", dest="outputFileName",
		help="Ordering filename", metavar="orderingFileName.nii.gz")
	# parser.add_argument("-d", dest="folder",
		# help="folder for to save the carpet plot", metavar="saving_dir")

	# import pdb;pdb.set_trace()
	# Here we are parsing the arguments
	args = parser.parse_args(raw_args)

	# Setting the arguments
	func 	= args.func		
	dtissue = args.dtissue
	outputFileName = args.outputFileName
 	# print('In gsReorder.py')
	# Once we have the files lets import some stuff	
	time_series,dimsF	= mrutils.import_nifti(func)
	tissue,dimsTs 		= mrutils.import_nifti(dtissue)

	# Will have to look GM time series without the inclusion masks
	CSF_ind	= 1
	GMI_ind	= 2
	WM_ind	= 3
	GM_dbscan = 4

	GM_vox=np.squeeze(np.where(tissue==GMI_ind))
	GMdbscan_vox=np.squeeze(np.where(tissue==GM_dbscan))

	# Get all the voxels
	# GM_vox=np.setdiff1d(GM_seg,mask_voxels[0])
	WM_vox=np.squeeze(np.where(tissue==WM_ind))
	CSF_vox=np.squeeze(np.where(tissue==CSF_ind))

	# Probably have to get rid of nans/zeros etc -- better not done here, this here is just to visualize	
	gm_time_series = time_series[GM_vox,:]
	gm_dbscan_time_series = time_series[GMdbscan_vox,:]
	wm_time_series = time_series[WM_vox,:]
	csf_time_series = time_series[CSF_vox,:]

	# Now get the GS reorder

	gm_dbscan_ordered_inds = generate_ordering(gm_dbscan_time_series)

	# A little clause here just incase you are not defining any other regions, make them empty
	gm_ordered_inds =[]
	wm_ordered_inds =[]
	csf_ordered_inds =[]

	if (np.shape(GM_vox)[0]>0):
		gm_ordered_inds = generate_ordering(gm_time_series)
 	if (np.shape(WM_vox)[0]>0):
		wm_ordered_inds = generate_ordering(wm_time_series)		
	if (np.shape(CSF_vox)[0]>0):
		csf_ordered_inds = generate_ordering(csf_time_series)
	

	# Now make a new matrix and save the nifti!
	tissue[GM_vox] = gm_ordered_inds
	tissue[GMdbscan_vox] = gm_dbscan_ordered_inds
	tissue[WM_vox] = wm_ordered_inds 
	tissue[CSF_vox] = csf_ordered_inds

	mrutils.nifti_save(tissue,dimsTs,outputFileName)

def generate_ordering(time_series_tissue):
	# Zscore the signal
	X_z = stats.zscore(time_series_tissue,axis=1,ddof=1)
	# Get the mean signal
	mean_signal = np.nanmean(X_z,axis=0)
	# Calculate correlations
	# import pdb;pdb.set_trace()
	# Heavy on memory - have to fix with a for loop.
	corr = np.corrcoef(X_z,mean_signal)	
	# Restrict the correlations to just look at the correlations of all time points with the mean signal
	corr = (corr[corr.shape[0]-1,0:corr.shape[0]-1])
	# Now retrieve the ordered indices.
	orderedIndex = np.argsort(corr)
 	return orderedIndex

if __name__ == '__main__':
    main()