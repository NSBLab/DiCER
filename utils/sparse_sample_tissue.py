# A function to sparsely sample the tissue mask

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning) 


from argparse import ArgumentParser
from os import path
import fMRI_in_out as mrutils
import numpy as np

parser = ArgumentParser(epilog="sparse_sample_tissue.py -- A python script to sparsely sample the tissue masks. Kevin Aquino 2018 BMH")
parser.add_argument("-o", dest="ordering_file", default="none",
	help="The ordering of the time series", metavar="ord")
parser.add_argument("-ds", dest="ds_factor", default="2",
	help="The downsample rate ", metavar="ord")
parser.add_argument("-ts", dest="tissue_file",
	help="tisue segmentation", metavar="tissue.nii.gz")
parser.add_argument("-tsd", dest="outputFile",
	help="Name for the downsampled ", metavar="dtissue_ds.nii.gz")


# ------------    Parsing the inputs from terminal:   ------------
args = parser.parse_args()
ordering_file 	= args.ordering_file
ds_factor 		= int(args.ds_factor)
tissue_file 	= args.tissue_file
outputFile 		= args.outputFile

# Load up the tissue file:
tissue,dimsTs 		= mrutils.import_nifti(tissue_file)
# Load up the ordering file:
orderingAll,dimsTs 		= mrutils.import_nifti(ordering_file)
new_tissue=tissue

maskValues = (1,2,3,4) # CSF, GM_bad, WM, GM_good
# import pdb;pdb.set_trace()
for i in maskValues:
	tissue_inds = np.squeeze(np.where(tissue==i))
	if(tissue_inds.shape[0]>0):
		# Now after getting the tissue, get the ordering, and order that list
		ordered_inds = np.argsort(orderingAll[tissue_inds])
		# In this ordered list, downsample this list. This them forms a sparse tissue mask where the sparsity is based on the correlation to the mean signal.
		downsampled_ordering = ordered_inds[range(0,ordered_inds.shape[0],ds_factor)]
		remove_inds = np.setdiff1d(ordered_inds,downsampled_ordering)
		remove_inds_from_tissue = tissue_inds[remove_inds]
		# Make it so that this sparse sampling of the ordering is applied to the tissue mask, by masking this sparse sample. This makes the rest of the code work
		# This approach is instead of doing voxel shift of resolution.
		new_tissue[remove_inds_from_tissue] = 0

# new_tissue = new_tissue*0
# Now save it all
import nibabel as nib
mrutils.nifti_save(new_tissue,dimsTs,outputFile)	

# Now annoyingly, this does not preserve the header info, here is a way to do it:
img = nib.load(outputFile)
img_ts = nib.load(tissue_file)
new_img = nib.nifti1.Nifti1Image(img.get_data(), None, header=img_ts.header)
nib.save(new_img,outputFile)



