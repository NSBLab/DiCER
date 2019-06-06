#!/usr/local/bin/python3
# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
import sys,os
sys.path.insert(1, os.path.join(sys.path[0], '..'))
from utils import fMRI_in_out
from scipy import stats
from sklearn.cluster import DBSCAN
from sklearn import metrics
from sklearn.preprocessing import StandardScaler
from sklearn import linear_model
import warnings

#-------------------------------------------------------------------------------
# Don't give this annoying scipy warning:
warnings.filterwarnings(action="ignore",module="scipy",message="^internal gelsd")

#-------------------------------------------------------------------------------
# Parameters:
#-------------------------------------------------------------------------------
# ---dbscan parameters---
# label for the dbscan parameter set:
paramSet = 'liberal'

# eps: distance defining neighbors (larger values match less-correlated neighbors)
# propSamplesDense: proportion of samples in a 'dense' neighborhood
if paramSet=='veryLiberal':
    eps = 0.70 #sys.argv[2]
    propSamplesDense = 0.05 # sys.argv[3] #0.005
elif paramSet=='liberal':
    eps = 0.60
    propSamplesDense = 0.01

# Force stop after a certain number of iterations
maxIterations = 5

# Minimum proportion of core samples to include a cluster:
# (hopefully this can be removed if other parameters are set properly)
minPropInCore = 0.01

#-------------------------------------------------------------------------------
# Where to read data in from:
# inputsFromTerminal = False
inputsFromTerminal = True

# Whether to save out spatial maps of voxels contributing to regressor at each
# iteration:
saveSpatialMaps = True
saveAltGM = True

#-------------------------------------------------------------------------------
# Label in mask to extract time-series data
maskLabel = 4
# Downsample to a subset of voxels (for speed) [set to 0 for no downsampling]:
downSampleRate = 0
# How to compute mean of a cluster (from all samples or just core samples?)
# meanFromJustCore = False
# Flip voxels negatively correlated with cluster center:
flipToAlign = True
# Cluster on absolute correlations:
clusterOnAbs = True

#-------------------------------------------------------------------------------
# Plotting parameters (for testing performance):
doPlot = False
if doPlot:
    import matplotlib.pyplot as plt
    Vdev = 1.2

#-------------------------------------------------------------------------------
def downsampleData(dataMat,downSamplingRate=0):
    "Simply downsample input data matrix by a given factor"
    if downSamplingRate==0:
        print('No downsampling')
        dataMatDown = dataMat
    else:
        print('Downsampled a factor of %u' % downSamplingRate)
        dataMatDown = dataMat[range(0,X.shape[0],downSamplingRate),:]
    return dataMatDown
#-------------------------------------------------------------------------------
def computeD(X,theMetric='correlation'):
    "Compute pairwise distances between rows of a matrix"
    print("Using %s distances between %u rows" % (theMetric,X.shape[0]))
    Dij = metrics.pairwise.pairwise_distances(X,metric=theMetric)
    # Convert to absolute correlation distances:
    Dij_abs = 1-np.abs(1-Dij)
    return Dij,Dij_abs
#-------------------------------------------------------------------------------
def clusterMe(D,eps,minSamplesDense):
    "Peform dbscan clustering on a pairwise distance matrix"
    numVoxels = D.shape[0]

    # Check D is well-behaved:
    if not np.isfinite(D).all():
        raise ValueError('Distance matrix contains non-finite values...?')

    # Peform DBSCAN clustering:
    db = DBSCAN(eps=eps,min_samples=minSamplesDense,metric='precomputed').fit(D)

    # Basic processing:
    labels = db.labels_
    isCoreSample = np.zeros_like(labels, dtype=bool)
    isCoreSample[db.core_sample_indices_] = True
    # Count the number of clusters formed (ignoring noise, assigned -1)
    numClusters = len(set(labels)) - (1 if -1 in labels else 0)

    # Count core samples of each cluster:
    numCore = [sum(np.logical_and(labels==k,isCoreSample)) for k in range(numClusters)]
    # Label small clusters based on a minimum number of core samples:
    smallThreshold = np.ceil(minPropInCore*numVoxels)
    isTooSmall = numCore < smallThreshold
    if np.any(isTooSmall):
        print('Removing %u small clusters (<%u core samples)' % (sum(isTooSmall),smallThreshold))
        ind_tooSmall = np.nonzero(isTooSmall)[0]
        for k in ind_tooSmall:
            isk = labels==k
            isCorek = np.logical_and(isk,isCoreSample)
            print('Removing cluster with %u/%u core/total samples' %(sum(isCorek),sum(isk)))
            labels[isk] = -1
            isCoreSample[isCorek] = False
        # Recompute number of clusters
        labelSet = set(labels)
        numClusters = len(labelSet) - (1 if -1 in labels else 0)
        labelList = list((labelSet - set([-1])))
        # Renumber clusters:
        for [k,label] in enumerate(labelList): # keep -1 labeling as -1
            isk = labels==label
            labels[isk] = k

    # Print basic info to screen:
    print('Estimated number of clusters: %d' % numClusters)
    print('Samples unassigned to any cluster: %u/%u' % (sum(labels==-1),numVoxels))
    for k in range(numClusters):
        isk = labels==k
        iskcore = np.logical_and(isk,isCoreSample)
        print('Samples assigned to cluster %u: %u (%u core)' % (k+1, sum(isk),sum(iskcore)))

    return labels,isCoreSample
#-------------------------------------------------------------------------------
def aGMR(X):
    "Estimate a global common signal, flipping negatively-correlated voxels"
    # (iteratively until convergence)
    numVoxels = X.shape[0]

    flipCount = 1
    iterationNum = 0
    X_aligned = np.copy(X)
    while flipCount > 0:
        iterationNum = iterationNum + 1
        globalMean = stats.zscore(np.mean(X_aligned,axis=0),ddof=1)
        # Flip row if Pearson correlation to globalMean is negative
        # k = 0
        # globalMean[0,:].shape
        # Xd[0,:].shape
        # a = stats.pearsonr(globalMean[0,:],Xd[0,:])
        flipCount = 0
        for k in range(numVoxels):
            R = stats.pearsonr(globalMean,X_aligned[k,:])
            if (R[0] < 0):
                X_aligned[k,:] = -X_aligned[k,:]
                flipCount = flipCount + 1

        print('Iteration %u: Flipped %u/%u time series negatively correlated to the global mean'
                % (iterationNum,flipCount,numVoxels))
    return globalMean
#-------------------------------------------------------------------------------
def GiveMeMeanTraces(X,D,labels,isCoreSample,clusterCenterOnlyFromCore=False):
    "Compute the cluster mean time traces"
    numTime = X.shape[1]

    numClusters = len(set(labels)) - (1 if -1 in labels else 0)
    globalMean = stats.zscore(np.mean(X,axis=0),ddof=1)

    meanTraces = np.zeros((numClusters,numTime))
    for k in range(numClusters):
        # Convert all data to relate just to cluster k:
        isk = (labels==k)
        if sum(isk)==0:
            print('No samples in cluster %u??!?!' % k)
        X_k = X[isk,:]
        D_k = D[isk,:][:,isk]
        D_abs_k = 1 - np.abs(1-D_k) # abs-correlation distances from cluster center

        # Determine a cluster center
        if clusterCenterOnlyFromCore:
            # Cluster center is the most central of core cluster samples:
            isCore_k = isCoreSample[isk]
            print('Cluster center as most central of core cluster samples' % sum(isCore_k))
            D_abs_k_core = D_abs_k[isCore_k,:][:,isCore_k] # abs-correlation distances from cluster center
            sumD = np.sum(D_abs_k_core,axis=0)
            isMin = np.argmin(sumD)
            # Convert this index (in core reference) of the minimum (in cluster indices)
            isCore_k_ind = np.nonzero(isCore_k)[0]
            min_ind_k = isCore_k_ind[isMin]
            # print('In core, minimum at %u' % (isMin))
            # print('Minimum at %u' % (min_ind_k))
        else:
            # Cluster center is the most central of all cluster samples (ignoring assignment to core):
            print('Cluster center as most central of all %u cluster samples' % sum(isk))
            sumD = np.sum(D_abs_k,axis=0)
            min_ind_k = np.argmin(sumD)

        # if doPlot:
        #     plt.hist(sumD,bins='auto')
        #     plt.xlabel('sum of distances to other cluster members')
        #     plt.show()

        # Flip time traces of voxels that are negatively correlated to the cluster center
        X_k_aligned = np.copy(X_k)
        if flipToAlign:
            R_to_centroid = 1 - D_k[min_ind_k,:]
            flipMe = (R_to_centroid < 0) # correlation distance > 1 => correlation < 0
            # if doPlot:
            #     plt.hist(R_to_centroid,bins='auto')
            #     plt.xlabel('correlation to cluster centroid')
            #     plt.show()
            X_k_aligned[flipMe,:] = -X_k_aligned[flipMe,:]
            print('Flipping %u/%u time series in cluster %u negatively correlated to the cluster center'
                        % (sum(flipMe),len(flipMe),k+1))

        # Compute the representative, mean trace for this cluster:
        # if meanFromJustCore:
        #     print('Cluster mean taken only from %u core samples' % sum(isCore_k))
        #     X_k = X[isCore_k,:]
        # else:
        meanTraces[k,:] = stats.zscore(np.mean(X_k_aligned,axis=0),ddof=1)
        print('Cluster mean taken from all %u samples' % sum(isk))

        # For visualization, ensure final sign is in the same broad orientation
        # as the GSR time trace:
        corr_mean = np.corrcoef(meanTraces[k,:],globalMean)
        corr_mean[0,1] < 0
        if corr_mean[0,1] < 0:
            meanTraces[k,:] = -meanTraces[k,:]

        if doPlot:
            t = np.arange(0,numTime)
            plt.figure(num=None,figsize=(10,8),dpi=80,facecolor='w',edgecolor='k')
            if flipToAlign:
                ax = plt.subplot(3,1,1)
                # ax.plot(t,coreMean,'-g')
                ax.plot(t,globalMean,'-b',label='GS')
                ax.plot(t,meanTraces[k,:],'-k',label='mean_k')
                ax.plot(t,stats.zscore(X_k_aligned[min_ind_k,:],axis=0),'-r',label='clusterCenter')
                ax.legend()
                ax.set_xlim(0,numTime)
                ax = plt.subplot(3,1,2)
                PlotSimpleZscoredMatrix(X_k,ax)
                plt.title('X_k')
                ax = plt.subplot(3,1,3)
                PlotSimpleZscoredMatrix(np.vstack((X_k_aligned[~flipMe,:],X_k_aligned[flipMe,:])),ax)
                plt.title('X_k_aligned (grouped by flip)')
            else:
                ax = plt.subplot(2,1,1)
                ax.plot(t,meanTraces[k,:],'-k')
                ax.set_xlim(0,numTime)
                ax = plt.subplot(2,1,2)
                PlotSimpleZscoredMatrix(X_k_aligned,ax)
                plt.title('X_k_aligned')
            plt.show()

            # if meanFromJustCore:
            #     plt.matshow(X_k[min_ind_k,:],vmin=-Vdev,vmax=Vdev)
            #     plt.show()
            # plt.matshow(np.vstack((X_k[flipMe,:],X_k[~flipMe,:])),vmin=-Vdev,vmax=Vdev)
            # plt.matshow(X_k,cmap=plt.cm.viridis,aspect='auto',vmin=-Vdev,vmax=Vdev)
            # plt.show()
            # plt.matshow(X_k[~flipMe,:],vmin=-Vdev,vmax=Vdev)
            # plt.show()

    return meanTraces
#-------------------------------------------------------------------------------
def GetResidual(X,regressors):
    "Compute residual of a linear regression applied to each row of a matrix"

    Xresid = np.zeros_like(X)
    if regressors.shape[1] > regressors.shape[0]:
        regressors = np.transpose(regressors)

    numVoxels = X.shape[0]
    for k in range(numVoxels):
        regr = linear_model.LinearRegression()
        regr.fit(regressors,X[k,:])
        Xresid[k,:] = X[k,:] - regr.predict(regressors)
        # m,c = np.linalg.lstsq(A,y)[0]
    return Xresid
#-------------------------------------------------------------------------------
def Correction(X):
    "Perform a single iteration of dbscan cluster-correction"
    global minSamplesDense
    numTime = X.shape[1]

    #---------------------------------------------------------------------------
    # 1. Compute pairwise distances:
    Dij,Dij_abs = computeD(X,theMetric='correlation')

    #---------------------------------------------------------------------------
    # 2. Do clustering on correlation-based distances:
    if clusterOnAbs:
        print('Clustering on absolute correlation distances')
        labels,isCoreSample = clusterMe(Dij_abs,eps,minSamplesDense)
    else:
        print('Clustering on raw correlation distances')
        labels,isCoreSample = clusterMe(Dij,eps,minSamplesDense)
    numRegressors = len(set(labels)) - (1 if -1 in labels else 0)

    #---------------------------------------------------------------------------
    # 3. Compute regressors as (?flipped?) mean of the core samples of each cluster:
    if numRegressors > 0:
        # Compute regressors:
        regressors = GiveMeMeanTraces(X,Dij,labels,isCoreSample)
        # Regress out from X:
        Xresid = GetResidual(X,regressors)
    else:
        regressors = np.empty(shape=(0,0))
        Xresid = X

    #---------------------------------------------------------------------------
    # 4. Ensure all time traces are z-scored:
    Xresid_z = stats.zscore(Xresid,axis=1,ddof=1)

    #---------------------------------------------------------------------------
    # 5. Prepare binary spatial map of voxels involved in estimating the regressor(s):
    spatialMap = np.zeros_like(labels)
    spatialMap[labels != -1] = 1 # (reachable samples labeled '1')
    spatialMap[isCoreSample] = 2 # (core samples labeled '2')

    return Xresid_z,regressors,spatialMap
#-------------------------------------------------------------------------------
def PlotSimpleZscoredMatrix(X,ax):
    # First zscore *across rows*:
    X_z = stats.zscore(X,axis=1,ddof=1)
    ax.matshow(X_z,cmap=plt.cm.viridis,aspect='auto',vmin=-Vdev,vmax=Vdev)
#-------------------------------------------------------------------------------
def PlotComparison(X,X_GSR,X_aGMR,Xcorrs):
    "Compare GSR and aGMR correction methods as carpet plots"
    plt.figure(num=None,figsize=(14,6),dpi=80,facecolor='w',edgecolor='k')
    ax = plt.subplot(1,5,1)
    PlotSimpleZscoredMatrix(X,ax)
    plt.title(subID)
    ax = plt.subplot(1,5,2)
    PlotSimpleZscoredMatrix(X_GSR,ax)
    plt.title('GSR(1)')
    ax = plt.subplot(1,5,3)
    PlotSimpleZscoredMatrix(X_aGMR,ax)
    plt.title('aGMR(1)')
    ax = plt.subplot(1,5,4)
    PlotSimpleZscoredMatrix(Xcorrs[1],ax)
    plt.title('DBSCAN(1)')
    ax = plt.subplot(1,5,5)
    PlotSimpleZscoredMatrix(Xcorrs[-1],ax)
    plt.title('DBSCAN(%u)' % (len(Xcorrs)-1))
    plt.show()
#-------------------------------------------------------------------------------
def PlotDBSCANprogress(X_DB):
    "Compare DBSCAN correction across iterations"
    numIterations = len(X_DB)
    plt.figure(num=None,figsize=(14,6),dpi=80,facecolor='w',edgecolor='k')
    for it in range(numIterations):
        ax = plt.subplot(1,numIterations,it+1)
        PlotSimpleZscoredMatrix(X_DB[it],ax)
        plt.title('DBSCAN(%u)' % it)
    plt.show()
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# def main(subID):
subID = 50051

global minSamplesDense # (define global)

#---------------------------------------------------------------------------
# Load data:
ts_file,mask_file,ordering_file,saveCSV_dir,subjectName = fMRI_in_out.giveMeFileNames(inputsFromTerminal,subID)
X = fMRI_in_out.timeSeriesData(ts_file,mask_file,maskIndex=maskLabel)
# X = pd.read_csv(ts_file,header=None).values

#-------------------------------------------------------------------------------
# Downsample for speed:
Xd = downsampleData(X,downSampleRate)

#-------------------------------------------------------------------------------
# Check data is well-behaved:
if not np.isfinite(Xd).all():
    raise ValueError('fMRI time series contain non-finite values.')
# Find (and exclude) constant voxels:
isConstant = (np.std(Xd,axis=1,ddof=1)==0)
if np.any(isConstant):
    Xd = Xd[~isConstant,:]
    print('Ignoring %u constant voxels' % np.sum(isConstant))

#-------------------------------------------------------------------------------
# Reorder for visualization:
from fmriprepProcess import clusterReorder
rowOrdering = clusterReorder.reorderMatrixRows(Xd)
Xd = Xd[rowOrdering,:]

#---------------------------------------------------------------------------
# Set parameters on data shape
numVoxels,numTime = Xd.shape
minSamplesDense = np.ceil(numVoxels*propSamplesDense)
print('Clustering %s' % ts_file)
print('Using eps = %f, minSamplesDense = %u (/%u)' % (eps,minSamplesDense,numVoxels))

#-------------------------------------------------------------------------------
# Iterative dbscan correction:
numRegressors = 0
numRegressorsNow = 1 # start with a dummy value
numRegressorPerIteration=[]
itNum = 1 # iteration number
Xcorrs = [] # List of iteratively-corrected fMRI matrices
Xcorrs.append(Xd)
spatialMaps = []
while numRegressorsNow > 0:
    # Do a round of dbscan correction:
    Xcorr,regressorsNow,spatialMap = Correction(Xcorrs[itNum-1])

    # Number of regressors used in this iteration:
    numRegressorsNow = regressorsNow.shape[0]
    print('ITERATION %u: Corrected for %u regressor(s)!' % (itNum,numRegressorsNow))

    # Append to list of iteratively corrected versions (if correction was done):
    if numRegressorsNow > 0:
        Xcorrs.append(Xcorr)
        spatialMaps.append(spatialMap)

    if doPlot and (itNum==1 or numRegressorsNow>0):
        plt.figure(num=None,figsize=(10,8),dpi=80,facecolor='w',edgecolor='k')
        t = np.arange(0,numTime)
        ax = plt.subplot(3,1,1)
        ax.set_xlim(0,numTime)
        globalMeanNow = np.mean(Xcorrs[itNum-1],axis=0);
        if numRegressorsNow > 0:
            ax.plot(t,stats.zscore(globalMeanNow,axis=0),'-b',label='GS')
            ax.plot(t,stats.zscore(regressorsNow[0,:],axis=0),'-k',label='dbscan_reg')
            ax.legend()
        ax = plt.subplot(3,1,2)
        PlotSimpleZscoredMatrix(Xcorrs[itNum-1],ax)
        plt.title('Corrected, iteration %u' % (itNum-1))
        ax = plt.subplot(3,1,3)
        PlotSimpleZscoredMatrix(Xcorrs[itNum],ax)
        plt.title('Corrected, iteration %u' % (itNum))
        plt.show()

    # Keep track of how many regressors have been used so far
    numRegressors = numRegressors + numRegressorsNow
    if itNum == 1:
        regressors = regressorsNow
        numRegressorPerIteration = np.append(numRegressorPerIteration,numRegressorsNow)
    else:
        if numRegressorsNow > 0:
            regressors = np.append(regressors,regressorsNow,axis=0)            
            # Just a command here to store how many regressors only if 
            numRegressorPerIteration = np.append(numRegressorPerIteration,numRegressorsNow)
    itNum = itNum + 1
    if (numRegressorsNow > 0) and (itNum > maxIterations):
        print('EXCEEDED maximum iterations: %u!' % (maxIterations))
        break



#-------------------------------------------------------------------------------
# Save regressors to csv file (via pandas):
fileNameRegressors = os.path.join(saveCSV_dir,('%s_dbscan_%s_regressors.csv' % (subjectName,paramSet)))
df = pd.DataFrame(regressors)
df.to_csv(fileNameRegressors)
print('Saved %u DBSCAN regressors to %s' % (numRegressors,fileNameRegressors))


fileNameRegressors = os.path.join(saveCSV_dir,('%s_dbscan_%s_regressor_count.csv' % (subjectName,paramSet)))
df = pd.DataFrame(numRegressorPerIteration)
df.to_csv(numRegressorPerIteration)
print('Saved %u DBSCAN number of regressors to %s' % (numRegressors,fileNameRegressors))

#-------------------------------------------------------------------------------
# Save spatial maps at each iteration to niftis:
if saveSpatialMaps:
    # Get the unstructured mask:
    M0,dimMask = fMRI_in_out.import_nifti(mask_file)
    fMRI_in_out.nifti_save(M0,dimMask,'testMasker.nii.gz')
    # Write each specific mask into the maskLabel
    for k in range(len(spatialMaps)):
        # import pdb;pdb.set_trace()
        fileNameMap_k = os.path.join(saveCSV_dir,('%s_dbscan_%s_spatialMap_%u.nii.gz' % (subjectName,paramSet,k+1)))
        M_k = np.zeros_like(M0)
        M_k[M0 == maskLabel] = spatialMaps[k]
        fMRI_in_out.nifti_save(M_k,dimMask,fileNameMap_k)
        print('Saved map of %u voxels used in iteration %u/%u to %s' %
                                    (np.sum(spatialMaps[k]>0),k+1,len(spatialMaps),fileNameMap_k))

#-------------------------------------------------------------------------------
# Also compute and save the aGM solution:
if saveAltGM:
    altGlobalMean = np.zeros((1,numTime))
    altGlobalMean[0,:] = aGMR(Xd);
    Xcorr_aGMR = GetResidual(Xd,altGlobalMean)
    df = pd.DataFrame(altGlobalMean)
    fileNameaGMR = os.path.join(saveCSV_dir,('%s_aGMR.csv' % subjectName))
    df.to_csv(fileNameaGMR)
    print('Saved alt-GM signal to %s' % fileNameaGMR)

#-------------------------------------------------------------------------------
# Final before-after assessment and comparison to GSR/alt-GSR:
if doPlot:
    # Compute the GSR & alt-GSR solutions:
    globalMean = np.zeros((1,numTime))
    globalMean[0,:] = np.mean(Xd,axis=0);
    Xcorr_GSR = GetResidual(Xd,globalMean)
    # Xd_trick = np.vstack((Xd,-globalMean[0,:]))
    # Plot:
    PlotComparison(Xd,Xcorr_GSR,Xcorr_aGMR,Xcorrs)
    PlotDBSCANprogress(Xcorrs)


    # t = np.arange(0,numTime)
    # ax = plt.subplot(2,2,1)
    # ax.plot(t,globalMean[0,:], '-k')
    # ax.set_xlim(0,numTime)
    # ax = plt.subplot(2,2,3)
    # PlotSimpleZscoredMatrix(Xd,ax)
    # ax = plt.subplot(2,2,2)
    # PlotSimpleZscoredMatrix(Xcorr_GSR,ax)
    # ax = plt.subplot(2,2,4)
    # PlotSimpleZscoredMatrix(Xcorr_aGMR,ax)
    # plt.show()


#-------------------------------------------------------------------------------
# Save corrected data to a nifti file:
# if inputsFromTerminal:
#     # Corrected output to nifti:
#     XcorrFull = np.zeros((dimIn[0]*dimIn[1]*dimIn[2],dimIn[3]))
#     XcorrFull[M==1,:] = Xcorr # put corrected values into the mask
#     fileNameOut = ('sub%u_dbscan_%s' % (subID,paramSet))
#     fMRI_in_out.nifti_save(XcorrFull,dimIn,fileNameOut)
# else:
#     # Output (corrected data) to csv file:
#     fileNameOut = ('DBSCAN_%s_Xcorr_sub-%s.csv' % (paramSet,subID))
#     df = pd.DataFrame(Xcorr)
#     df.to_csv(fileNameOut)
#     print('Saved corrected data to %s' % fileNameOut)

#-------------------------------------------------------------------------------
# Don't plot in the commandline implementation:
# sys.exit()

# if __name__ == "__main__": main()
