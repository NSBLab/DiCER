# Kevin Aquino
# Brain and Mental Health Research Hub
# 2019
#
# This is a python script to generate a carpet plot from given arguments.

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

	CIFTI_SIZE=98301
	# tissue,mask_voxels,time_series):
		
	# Parse in inputs
	from argparse import ArgumentParser
	parser = ArgumentParser(epilog="reshapeSurfaceNifti.py -- A function to reshape a surface nifti so that all dimensions have a size >1 . Kevin Aquino 2018 BMH")
	parser.add_argument("-f", dest="func",
		help="functional MRI time series", metavar="fMRI.nii.gz")
	parser.add_argument("-o", dest="outputFileName",
		help="output of functional MRI time series", metavar="out.nii.gz")


	# import pdb;pdb.set_trace()
	# Here we are parsing the arguments
	args = parser.parse_args(raw_args)

	# Setting the arguments
	func 	= args.func		
	outputFileName = args.outputFileName
 	# print('In gsReorder.py')
	# Once we have the files lets import some stuff	
	time_series,dimsF	= mrutils.import_nifti(func)
	# import pdb;pdb.set_trace()
	# Need to have other clauses for fsaverage data
	if (dimsF[0]*dimsF[1] == CIFTI_SIZE):
		print('CIFTI-like NIFTI detected! i.e. total length is %u. Reshaping to fill in all dimensions!' % (CIFTI_SIZE))
		dimOut = [7,4681,3,dimsF[2]]
		time_series_new=np.reshape(time_series,dimOut,order="F")
		mrutils.nifti_save(time_series_new,dimOut,outputFileName)

if __name__ == '__main__':
    main()