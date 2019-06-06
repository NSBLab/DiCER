# DiCER

(D)(i)iffuse (C)luster (E)stimation and (R)egression.

This repository holds all the DiCER code to denoise resting state fMRI data. For more information of the algorithm see the following BioRxiv preprint here ---> 

# Instructions:
DiCER is set to run post fMRIprep (v1.1.1) as a method to additionaly denoise data that has already undergone ICA-AROMA denoising.

This has been tested on Linux and MacOSX v.10.12.6 and works as a collection of bash and python scripts tested with anaconda/5.0.1-Python2.7.

You will need to set the following bash environment variables:
        export FMRIPREP_DIR
        export space_variant
        export subject
        export SCAN_ID

and then run:

>> sh carpetCleaner.sh

## If you would like to use DiCER with your data please download the repository and feel free to contact us via Issues within this repository!

