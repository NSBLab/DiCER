#-------------------------------------------------------------------------------
# OLD PLOTTING BELOW:
#-------------------------------------------------------------------------------
# Plot the time traces for each cluster:
t = np.arange(0,numTime)
for k in range(numClusters):
    ax = plt.subplot(numClusters,1,k+1)
    ax.plot(t,meanTraces[k,:], '-k')
    isk = labels==k
    isCorek = np.logical_and(isk,isCoreSample)
    ax.set_title('Cluster: %u (%u/%u)' % ((k+1),sum(isCorek),(sum(isk))))
plt.show()

#-------------------------------------------------------------------------------
# Plot core samples as carpet plot:
plt.figure(figsize=(20,10))
for k in range(numClusters):
    isk = labels==k
    isCorek = np.logical_and(isk,isCoreSample)
    if k==0:
        X_core = X[isCorek,:]
    else:
        X_core = np.vstack((X_core,X[isCorek,:]))
meanTrace = np.mean(X_core,axis=0)
plt.plot(t,meanTrace, '-k')
plt.show()

plt.matshow(X_core, cmap=plt.cm.viridis, aspect='auto', vmin=-2, vmax=2)
plt.show()

#-------------------------------------------------------------------------------
isCorek = np.logical_and(isk,isCoreSample)
for k in range(numClusters):
    isk = labels==k
    # All core samples:
    isCorek = np.logical_and(isk,isCoreSample)
    isNoncorek = np.logical_and(isk,~isCoreSample)
    X_cluster_noncorek = X[isNoncorek,:]
    X_cluster_corek = X[isCorek,:]
    X_clusterk = np.vstack((X_cluster_noncorek, X_cluster_corek))

    # ax = plt.subplot(numClusters,1,k+1)
    ax = plt.subplot(numClusters+1,2,k*2+1)
    ax.matshow(X_cluster_corek, cmap=plt.cm.plasma, aspect='auto')
    ax = plt.subplot(numClusters+1,2,k*2+2)
    ax.matshow(X_cluster_noncorek, cmap=plt.cm.viridis, aspect='auto')
    # plt.title('Cluster: %u (%u/%u)' % ((k+1),sum(np.logical_and(isk,isCoreSample)),(sum(isk))))
    plt.show()

# print("Silhouette Coefficient: %0.3f" % metrics.silhouette_score(X, labels))
