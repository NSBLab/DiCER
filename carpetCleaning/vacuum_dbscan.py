# Parse in inputs
# def main(nifti_gz,subject,folder,dbscan_regressors):

from argparse import ArgumentParser
parser = ArgumentParser(epilog="vacuum_dbscan.py -- A function to correct data using the dbscan regressors. Kevin Aquino 2018 BMH")
parser.add_argument("-f", dest="func",
	help="dbscan input", metavar="fMRI")
parser.add_argument("-db", dest="dbscan_regressors",
	help="dbscan regressors in csv outpu", metavar="dbscan_reg.csv")
parser.add_argument("-s", dest="subject",
	help="The subject", metavar="subject_label")
parser.add_argument("-d", dest="folder",
	help="folder to save the file after cleaning with the regressors.", metavar="saving_dir")
parser.add_argument("-of", dest="outputFlag", default="dbscan",
	help="(optional) a flag to switch between dbscan and aGMR.", metavar="saving_dir")


# Here we are parsing the arguments
args = parser.parse_args()

# Setting the arguments
nifti_gz 		  = args.func
subject 	      = args.subject
folder 			  = args.folder
dbscan_regressors = args.dbscan_regressors
outputFlag 		  = args.outputFlag

# dbscan_regressors="sub10159_dbscan_liberal_regressors.csv"
# folder="/Users/kevinaquino/projects/GSR_data/UCLA_data_niftis/fmriprep/"
# subject="sub10159" # bah subject name is different :(
# nifti_gz="sub-10159_task-rest_bold_space-MNI152NLin2009cAsym_variant-AROMAnonaggr+2P_preproc_detrended_hpf.nii.gz"

# Here look at the imports
# import pdb; pdb.set_trace()

if outputFlag=="aGMR":
	dbscan_tsv=folder+subject+"_aGMR.tsv"
else:
	dbscan_tsv=folder+subject+"_dbscan_liberal_regressors.tsv"


output=folder+nifti_gz[0:len(nifti_gz)-7]+"_"+outputFlag+".nii.gz"
nifti_gz=folder+nifti_gz

import csv
import numpy as np

with open(folder+dbscan_regressors, 'rb') as csvfile:
	spamreader = csv.reader(csvfile, delimiter=',')
	# row_count = sum(1 for row_dummy in spamreader)
	total = []
	counter = 0;
	# counter =
	for num,row in enumerate(spamreader):
		if(num>0):
			# print row
			val2=np.array(row)
			vals = val2.astype(float)
			total = np.append(total,vals[1:len(vals)])
			counter=counter+1
			nframes=len(row)-1

total2=np.reshape(total,(nframes,counter),order="F")

np.savetxt(dbscan_tsv, total2, delimiter="\t")

filtString = ""
for num in range(1,counter+1):
	if(num>1):
		filtString=filtString+","+str(num)
	else:
		filtString=filtString+str(num)

from subprocess import call
call_fslregfilt=["fsl_regfilt","-i",nifti_gz,"-o",output,"-d",dbscan_tsv,"-v","-f",filtString]
call(call_fslregfilt)
