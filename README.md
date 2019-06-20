# DiCER

(D)(i)iffuse (C)luster (E)stimation and (R)egression.

This repository holds all the DiCER code to denoise resting state fMRI data. For more information of the algorithm see the following BioRxiv preprint here ---> https://www.biorxiv.org/content/10.1101/662726v1

# Instructions:
DiCER is set to run post fMRIprep (v1.1.1) as a method to additionaly denoise data that has already undergone ICA-AROMA denoising.

This has been tested on Linux and MacOSX v.10.12.6 and works as a collection of bash and python scripts tested with anaconda/5.0.1-Python2.7.

# Dependencies:
AFNI
FSL
Python,SciPy,Pandas,Numpy,scikit-learn (as packaged with anaconda)

You will need to set the following bash environment variables:
+ export FMRIPREP_DIR
+ export space_variant
+ export subject
+ export SCAN_ID

and then run:

sh carpetCleaner.sh

To check out some of the reporting you get with DiCER please have a look at:
https://bmhlab.github.io/DiCER_results/

## If you would like to use DiCER with your data please download the repository and feel free to contact us via Issues within this repository!

# DICER_lightweight
If you have data that has not been fmriprep'd you can still run this code by running DiCER_lightweight

Typical usage with a functional image func, a T1w image T1w in path pathToFiles for subject SUBJECT_1 is invoked by the following:

`` 
sh DiCER_lightweight.sh -i $func -a $T1w -w $pathToFiles -s SUBJECT_1 -d
``

see sh DiCER_lightweight.sh -h for more options, note that "-d" is used to deterend and high-pass filter the data (Recommended). Note this assumes a nice segmentation by FAST. If you have your own tissue segmentation you can avoid this step above and use:

`` 
sh DiCER_lightweight.sh -i $func -t $tissueSeg -w $pathToFiles -s SUBJECT_1 -d
``

where tissueSeg is a nifti which has the labels, 1=CSF,2=GM,3=WM,4=Restricted GM i.e. Grey matter that is either eroded or just a subset of GM. The last label, 4, is the label that DiCER samples off to peform the correction. 

Note: this gives you a very lightweight HTML report, if you want more than just a light report you need to specify a confounds.tsv file where importantly the 4th column is a DVARS calculation and the 7th Column is a FD calculation (the rest of the .tsv can contains zeros).
