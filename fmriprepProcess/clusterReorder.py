# Reads in nfti files and outputs to an ordering file
import sys
import os
from matplotlib import pyplot as plt
from scipy.spatial import distance
from scipy.cluster import hierarchy
import numpy as np
import pandas as pd
from scipy import stats

# Import the little fmri_tools we need
sys.path.insert(1, os.path.join(sys.path[0], '..'))
from utils import fMRI_in_out

#-------------------------------------------------------------------------------
def reorderMatrixRows(X,distanceMetric='euclidean',linkageMethod='average',doOptimalLeaf=False):
    "Get reordering of rows of a matrix by clustering"

    # Find (and exclude) constant voxels:
    isConstant = (np.std(X,axis=1,ddof=1)==0)
    if np.any(isConstant):
        X = X[~isConstant,:]
        print('%u constant voxels ignored' % np.sum(isConstant))

    # z-score the remaining voxels:
    X = stats.zscore(X,axis=1,ddof=1)

    print('Filtered to %u x %u time series' % (X.shape[0],X.shape[1]))

    # Compute condensed pairwise distance matrix:
    # DataFrame.corr(method='Pearson',min_periods=1)
    dij = distance.pdist(X,metric=distanceMetric)
    print('%u %s distances computed!' %(dij.shape[0],distanceMetric))

    # Check D is well-behaved:
    if not np.isfinite(dij).all():
        raise ValueError('Distance matrix contains non-finite values...')

    # Compute hierarchical linkage structure:
    Z = hierarchy.linkage(dij,method=linkageMethod,optimal_ordering=doOptimalLeaf)
    print('%u objects agglomerated using average linkage clustering!' %(X.shape[0]))

    # Get voxel ordering vector:
    if np.any(isConstant):
        # Extend to the full size
        nodeOrdering = np.zeros_like(isConstant,dtype=int)
        nodeOrdering[~isConstant] = hierarchy.leaves_list(Z)
    else:
        nodeOrdering = hierarchy.leaves_list(Z)
    return nodeOrdering

#-------------------------------------------------------------------------------
def main(subID=10448,distanceMetric='euclidean',linkageMethod='average',doOptimalLeaf=False):

    # Additional parameters:
    doPlot = False

    # Load in data:
    ts_file,mask_file,ordering_file,saveCSV_dir,subjectName = fMRI_in_out.giveMeFileNames(True,subID) # might have to change this parser -- more error prone
    M,dimMask = fMRI_in_out.import_nifti(mask_file)
    Xraw,dimIn = fMRI_in_out.import_nifti(ts_file)

    # Cluster each mask:
    orderingVector = np.zeros_like(M,dtype=int)
    maskValues = (1,2,3,4) # CSF, GM_bad, WM, GM_good
    for i in maskValues:
        print('---Mask label: %u' % i)
        isMi = (M==i)
        if np.any(isMi):
            Xi = Xraw[isMi,:]
            nodeOrdering = reorderMatrixRows(Xi,distanceMetric=distanceMetric,
                            linkageMethod=linkageMethod,doOptimalLeaf=doOptimalLeaf)
            orderingVector[isMi] = nodeOrdering
        else:
            print('No voxels assigned to mask label %u' % i)

    # Save result back to file:
    fileNameClusterOrderOut = ts_file[:-7]+'_clusterorder.nii.gz'
    fMRI_in_out.nifti_save(orderingVector,dimMask,fileNameClusterOrderOut)
    print('Saved voxel ordering to %s' % fileNameClusterOrderOut)

    # Visualize:
    if doPlot:
        Vdev = 1.2
        for Ci in (1,2,3,4):
            ax = plt.subplot(2,2,Ci)
            X_z = stats.zscore(Xraw[M==Ci,:][orderingVector[M==Ci]],axis=1,ddof=1)
            ax.matshow(X_z,cmap=plt.cm.viridis,aspect='auto',vmin=-Vdev,vmax=Vdev)

if __name__ == "__main__": main()
