# A function here to make carpet plots and make a html report as well

# Have to clean this up, might make a main function as well to make this a little more tidy
from argparse import ArgumentParser
import subprocess
import shutil
from os import path
import carpetPlot
import plotDBthreads

parser = ArgumentParser(epilog="tapestry.py -- A function to take a list of fMRI preprocessed files, with masks and ordering and display a collection of carpet plots in a neat .html page. Kevin Aquino 2018 BMH")
parser.add_argument("-f", dest="func_list",
	help="functional MRI time series as a list", metavar="prepro1.nii.gz,prepro2.nii.gz,...")
parser.add_argument("-fl", dest="func_labels",
	help="a list of fMRI labels, this is seperated out because the fMRI nifits might be quite long in name", metavar="label1,label2,label3")
parser.add_argument("-o", dest="ordering_list", default="none",
	help="The ordering of the time series  (optional)", metavar="ord")
parser.add_argument("-l", dest="ordering_labels",
	help="Ordering labels  (optional)", metavar="label1,label2")
parser.add_argument("-ts", dest="dtissue",
	help="tisue segmentation", metavar="dtissue.nii.gz")
parser.add_argument("-s", dest="subject",
	help="The subject", metavar="subject_label")
parser.add_argument("-d", dest="folder",
	help="folder for to save the carpet plot", metavar="saving_dir")
parser.add_argument("-reg", dest="regressors",
	help="Regressors in .csv format (optional)", metavar="regressor_file.csv", default="none")
parser.add_argument("-cf", dest="confounds_file", default="none",
	help="Confounds file in .tsv fmriprep format (optional-made with fmriprep)", metavar="regressor_file.tsv")

# Put some stuff up -- ask to input fd and DVARS -- then also add a part to include the DBSCAN regressors

# In here have to add a seperate option to create a new page that makes a popup for DBSCAN!, now this can be quite cool to add 
# Either at the bottom or as a seperate page? not sure, maybe as a small javascript element that you can open or close? 
# Maybe for now as a part of a special part of the plot!

# ------------    Parsing the inputs from terminal:   ------------
args = parser.parse_args()
func_list 		= [str(item) for item in args.func_list.split(',')]
func_labels 	= [str(item) for item in args.func_labels.split(',')]
# mask 			= args.mask
ordering_list 	= [str(item) for item in args.ordering_list.split(',')]
ordering_labels = [str(item) for item in args.ordering_labels.split(',')]
dtissue 		= args.dtissue
subject 		= args.subject
folder 			= args.folder
regressors 		= args.regressors
confounds_file 	= args.confounds_file
# ----------------------------------------------------------------

# Run these for each variation for each functional
for func_no,func_label in enumerate(func_labels):
	for order_no,order_label in enumerate(ordering_labels):		
		carpetPlot.main(['-f',func_list[func_no],'-s',subject,'-l',func_label+'_'+order_label,'-d',folder,'-ts',dtissue,'-ot',ordering_list[order_no]])
	carpetPlot.main(['-f',func_list[func_no],'-s',subject,'-l',func_label+'_random','-d',folder,'-ts',dtissue])

# This here saves the regressors if its all good
if regressors!="none":
	# subprocess.call(['python','plotDBthreads.py','-s',subject,'-l','regressor','-d',folder,'-reg',regressors,'-cf',confounds_file])
	plotDBthreads.main(['-s',subject,'-l','regressor','-d',folder,'-reg',regressors,'-cf',confounds_file])



# Now we add (by default) another ordering label because we always add in the random ordering as well
ordering_labels.insert(0,'random')


# Make a copy of the .css file that makes the webpage look much nicer:
dir_path = path.dirname(path.realpath(__file__))
shutil.copy2(dir_path+'/websiteStyle.css',folder+'/websiteStyle.css')

# ------------------------HTML report-------------------------
# Section here to write the html report
# Put it all together to make a report, and here is a piece of code to make every different ordering type html

fileH=open(folder+subject+'carpet.html','w')
fileH.write('<html><title>'+subject+'</title>\n')
fileH.write('<head><link rel="stylesheet" href="websiteStyle.css">\n')

# Here write some java script that is needed for the buttons to switch between different ordering
fileH.write('<script>\n')


for order_label in ordering_labels:
	fileH.write('function '+order_label+'()\n')
	fileH.write('{\n')
	for func_label in func_labels:
		fileH.write('document.getElementById("'+func_label+'").src="'+subject+func_label+'_'+order_label+'carpet.png";\n')
		fileH.write('document.getElementById("'+func_label+'tis'+'").src="'+subject+func_label+'_'+order_label+'tissue_carpet.png";\n')

	fileH.write('}\n')

fileH.write('</script>\n')
fileH.write('</head>\n')
# fileH.write('<div id="header"><h1>Common signal report</h1><div id="navigation"><a href="voxelmaps_index.html">Voxel Maps</a> | <a href="index.html">Carpet Plots</a></div></div>')
fileH.write('<div id="header"><h1>Carpet plot report</h1></div>\n')
fileH.write('<div id="content">\n')

# Here write buttons for each different order
fileH.write('<center><br><br><h2>Voxel ordering:</h2><div class="btn-group">\n')
for order_label in ordering_labels:
	fileH.write('<button class="button" onclick='+order_label+'()>'+order_label+'</button>\n')
fileH.write('</div>')
fileH.write('<p style="clear:both">\n')
fileH.write('<center><table><tr>\n')
# Here we are leaving for physiological (as well as FD and DVARS), currently empty but will add soon!
# fileH.write('<tr>')
# fileH.write('<td><a><img src="'+subject+'_physio.png" width=700px></a></td>')
# fileH.write('</tr>')

# Here now add a table row for each variant of the functional MRI plots

if regressors!="none":
	fileH.write('<tr>\n')
	fileH.write('<td><a><img src='+subject+'_regressors.png width=400px></a></td>\n')	
	fileH.write('<td><a><img src='+subject+'_regressors.png width=400px></a></td>\n')
	fileH.write('</tr>\n')

for func_label in func_labels:
	fileH.write('<tr>\n')
	fileH.write('<td><a><img id='+func_label+' src='+subject+func_label+'_'+ordering_labels[0]+'carpet.png width=400px></a></td>\n')
	fileH.write('<td><a><img id='+func_label+'tis'+' src='+subject+func_label+'_'+ordering_labels[0]+'tissue_carpet.png width=400px></a></td>\n')
	fileH.write('</tr>\n')

fileH.write('<p></p><br><br>\n')
fileH.write('</table>\n')
# fileH.write('</table>')
fileH.write('<br><br><br><br>\n')
fileH.write('<div id="legend">Figures on the left hand side are the inputs to DBSCANs algorithm (after a restrictive gray mask). Figures on the right are carpet plots at different tissue types. Black=DBSCANs input, RED=left over gray matter, YELLOW=WM voxels, WHITE=CSF.</div>\n')
fileH.write('<br><br><br><br>\n')
fileH.write('</center></div>\n')
fileH.write('</html>')

fileH.close()

# ------------------------HTML report-------------------------


# ------------------------Extra HTML report-------------------------

# ------------------------Extra HTML report-------------------------
