![](https://bmhlab.github.io/DiCER_results/DiCERImage.png)

# DiCER
(D)(i)iffuse (C)luster (E)stimation and (R)egression.

This repository holds all the DiCER code to denoise resting state fMRI data.

For more information on the algorithm and its performance, please see [our NeuroImage paper](https://doi.org/10.1016/j.neuroimage.2020.116614).

If you use DiCER please cite our paper:
Aquino et al. (2019). _Identifying and removing widespread signal deflections from fMRI data: Rethinking the global signal regression problem_. NeuroImage __212__: 116614.

# Instructions:
DiCER is set to run post fMRIprep (v1.1.1) as a method to additionaly denoise data that has already undergone ICA-AROMA denoising.

This has been tested on Linux and MacOSX v.10.12.6 and works as a collection of bash and python scripts tested with anaconda/5.0.1-Python2.7.

# Dependencies:
AFNI
FSL
Python, SciPy, Pandas, Numpy, scikit-learn (as packaged with anaconda)

You will need to set the following bash environment variables:
+ export FMRIPREP_DIR
+ export space_variant
+ export subject
+ export SCAN_ID

and then run:

```
sh carpetCleaner.sh
```

To check out some of the reporting you get with DiCER please have a look at our [DiCER results website](https://bmhlab.github.io/DiCER_results/).

# Some warnings (please read)
As with all unsupervised de-noising methods, sometimes over-correction can be an issue (see the discussion of this within the paper).
We thus urge investigators that use this method to look over the estimated noise regressors (from DiCER) and if over correction is suspected we reccomend to either: Remove these hamrful regressors from your noise removal OR to vary the DiCER parameters in your experiment.
Please see the code within `clusterCorrect.py` for more details. (This will be added as an input to `DiCER_lightweight` soon).

# DICER_lightweight (reccomended!)
If you have data that has not been fmriprep'd (or if your version of fMRIprep > v1.1.1( you can still run DiCER by running DiCER_lightweight.

Typical usage with a functional image func, a T1w image T1w in path pathToFiles for subject SUBJECT_1 is invoked by the following:

`` 
sh DiCER_lightweight.sh -i $func -a $T1w -w $pathToFiles -s SUBJECT_1 -d
``

see sh DiCER_lightweight.sh -h for more options, note that "-d" is used to deterend and high-pass filter the data (Recommended). Note this assumes a nice segmentation by FAST. If you have your own tissue segmentation you can avoid this step above and use:

`` 
sh DiCER_lightweight.sh -i $func -t $tissueSeg -w $pathToFiles -s SUBJECT_1 -d
``

where tissueSeg is a nifti which has the labels, 1=CSF,2=GM,3=WM,4=Restricted GM i.e. Grey matter that is either eroded or just a subset of GM. The last label, 4, is the label that DiCER samples off to peform the correction. 

Note: this gives you HTML report without FD traces (its set to zero), and it calculates DVARS according to Nichols et al's standardized DVARS technique. 

Adding movement parameters to the report

``
sh DiCER_lightweight.sh -i $func -t $tissueSeg -w $pathToFiles -s SUBJECT_1 -d -m movFile.txt
``

Now adds FD to the confounds file and displays a calcution of FD from a movement parameters file (a nframesX6 text file with realignment/motion correction parameters).

# Notes/warnings
Currently DiCER is suited for whole-brain rsfMRI studies and all the tools are tailored for this purpose. However estimation of the noisy regressors can come from a very coarse representation of the data. So working with higher resolution data can be achieved by using a downsampled version of the data and then applying `fsl_regfilt` with the discovered signals to the original resolution. Currently this is being tested on higher-resolution 7T fMRI task and rest data. 

### Warnings!!!
New fMRIprep (for v.1.4 onwards - tissue ordering is wrong, take care, will NOT work out of the box!)

## If you would like to use DiCER with your data please download the repository and feel free to contact us via Issues within this repository!
