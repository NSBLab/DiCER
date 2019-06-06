# fMRI Cluster Correct

## Correction
```python
clusterCorrect.py
```


## Cluster-reorder

```python
clusterReorder.py
```

## Master script:
```bash
carpetCleaner.sh
```
This takes the data from a fmriprep prepro, uses DBSCAN to find the regressors then cleans the data by using these regressors in fslregfilt.

This is currently coded to run in serial -- but can be easily made to run in parallel (to do all of it!)
