# Python functions for reading files in from nifti and writing output to nifti
import nibabel as nib
import numpy as np
import sys
import os

#-------------------------------------------------------------------------------
def giveMeFileNames(inputsFromTerminal=True,subID=10460):
    "Deduce names of required files either from system inputs, or from a given subject ID"
    # Inputs from terminal: Mask_file,ordering_file,ts_file,saveCSV_dir
    if inputsFromTerminal:
        mask_file = sys.argv[1]
        ordering_file = sys.argv[2]
        ts_file = sys.argv[3]
        saveCSV_dir = sys.argv[4]
        subjectName = sys.argv[5]
    else:
        mask_file = os.path.join('DataNew',('sub-%u_T1w_space-MNI152NLin2009cAsym_variant_dtissue_masked.nii.gz' % subID))
        ordering_file = os.path.join('DataNew',('sub-%u_T1w_space-MNI152NLin2009cAsym_variant_gm_mask_gsordering.nii.gz' % subID))
        ts_file = os.path.join('DataNew',('sub-%u_task-rest_bold_space-MNI152NLin2009cAsym_variant-AROMAnonaggr+2P_preproc_detrended_hpf.nii.gz' % subID))
        saveCSV_dir = '.';
        subjectName = subID
    return ts_file,mask_file,ordering_file,saveCSV_dir,subjectName
#-------------------------------------------------------------------------------
def import_nifti(imageFile):
    "An import nifti function that takes care of the annoying last dimension"
    img = nib.load(imageFile)
    imgData = np.squeeze(img.get_data())
    dimensions = imgData.shape
    numDims = np.shape(dimensions)[0]
    if numDims==3:
        # Swap first two dimensions (to be compatible with freesurfer's MRIread):
        # imgData = np.transpose(imgData,(1,0,2))
        # Mask (or ordering) data
        print('Unfolded %ux%ux%u mask matrix using Fortran ordering' % (dimensions[0],dimensions[1],dimensions[2]))
        imgData = np.reshape(imgData,(dimensions[0]*dimensions[1]*dimensions[2]),order="F")
    elif numDims==4:
        # Swap first two dimensions (to be compatible with freesurfer's MRIread):
        # imgData = np.transpose(imgData,(1,0,2,3))
        # Time-series data
        print('Unfolded %ux%ux%ux%u time-series matrix using Fortran ordering' % (dimensions[0],dimensions[1],dimensions[2],dimensions[3]))
        imgData = np.reshape(imgData,(dimensions[0]*dimensions[1]*dimensions[2],dimensions[3]),order="F")
    return imgData,dimensions
#-------------------------------------------------------------------------------
def timeSeriesData(ts_file,mask_file,maskIndex=4):
    """
    Read in time-series data from nifti file and filter by a given mask index
    from the mask file
    """
    Xraw,dimIn = import_nifti(ts_file)
    print('Read in %ux%u time series data' % (Xraw.shape[0],Xraw.shape[1]))
    # Take values from the mask:
    M,dimMask = import_nifti(mask_file)
    # Apply the mask:
    X = Xraw[M==maskIndex,:]
    print('Filtered to %ux%u time series (in the mask)' % (X.shape[0],X.shape[1]))
    return X
#-------------------------------------------------------------------------------
def nifti_save(M,dimOut,fileName):
    "Saves matrix M to nifti, reshaping to the required dimensions"
    imgData = np.reshape(M,dimOut,order="F")
    numDims = np.shape(dimOut)[0]
    if numDims==3:
        # imgData = np.transpose(imgData,(0,1,2))
        print('Reshaped output to a %ux%ux%u matrix' % (imgData.shape[0],imgData.shape[1],imgData.shape[2]))
    elif numDims==4:
        imgData = np.transpose(imgData,(1,0,2,3))
        print('Reshaped output to a %ux%ux%ux%u matrix' % (imgData.shape[0],imgData.shape[1],imgData.shape[2],imgData.shape[3]))
    img = nib.Nifti1Image(imgData,np.eye(4))
    nib.save(img,fileName)
#-------------------------------------------------------------------------------
