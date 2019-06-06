# This script here to generate the general html report, make these inputs

# Have to clean this up, might make a main function as well to make this a little more tidy
from argparse import ArgumentParser
parser = ArgumentParser(epilog="bazaar.py -- A function to take a bunch of carpet reports and join them up together. Kevin Aquino 2018 BMH")
parser.add_argument("-fl", dest="func_labels",
	help="a list of fMRI labels, this is seperated out because the fMRI nifits might be quite long in name", metavar="label1,label2,label3")
parser.add_argument("-l", dest="ordering_labels",
	help="Ordering labels  (optional)", metavar="label1,label2")
parser.add_argument("-sl", dest="subject_list",
	help="A list of subjects that have been processed with tapestry.py", metavar="subject_list.txt")
parser.add_argument("-d", dest="folder",
	help="folder for to save the carpet plot", metavar="saving_dir")

#--------------------    Parsing the inputs from terminal:   -------------------
args = parser.parse_args()
func_labels 	= [str(item) for item in args.func_labels.split(',')]
ordering_labels = [str(item) for item in args.ordering_labels.split(',')]
subject_list	= args.subject_list
folder 			= args.folder
#-------------------------------------------------------------------------------

# Define empty list:
subjects = []
# subject_list = '/Users/kevinaquino/Documents/GSRSimulation/ucla_fmriprep.txt'
# func_labels=['ICA-AROMA']
# ordering_labels=['random','GS_ordering']
# folder='/Users/kevinaquino/projects/GSR_data/UCLA_data_niftis/fmriprep_html/'

# Open file and read the content in a list
with open(subject_list, 'r') as filehandle:
    subjects = [current_subject.rstrip() for current_subject in filehandle.readlines()]

# Now that you have the list, go through each of them and add stuff

# ------------------------HTML report-------------------------
# Section here to write the html report
# Put it all together to make a report, and here is a piece of code to make every different ordering type html

fileH=open(folder+'general_report.html','w')
fileH.write('<html><title>Common signal report</title>\n')
fileH.write('<head><link rel="stylesheet" href="websiteStyle.css">\n')

# Here write some java script that is needed for the buttons to switch between different ordering
fileH.write('<script>')

for order_label in ordering_labels:
	fileH.write('function '+order_label+'()\n')
	fileH.write('{\n')
	for func_label in func_labels:
		for subject in subjects:
			fileH.write('document.getElementById("'+func_label+subject+'").src="'+subject+func_label+'_'+order_label+'carpet.png";\n')

	fileH.write('}')

fileH.write('</script>\n')
fileH.write('</head>\n')
# fileH.write('<div id="header"><h1>Common signal report</h1><div id="navigation"><a href="voxelmaps_index.html">Voxel Maps</a> | <a href="index.html">Carpet Plots</a></div></div>')
fileH.write('<div id="header"><h1>Common signal report</h1></div>\n')
fileH.write('<div id="content"> \n')

# Here write buttons for each different order
fileH.write('<center><br><br><h2>Voxel ordering:</h2><div class="btn-group">\n')
for order_label in ordering_labels:
	fileH.write('<button class="button" onclick='+order_label+'()>'+order_label+'</button>\n')
fileH.write('</div>\n')
fileH.write('<p style="clear:both">\n')
fileH.write('<center><table><tr>\n')
# Here we are leaving for physiological (as well as FD and DVARS), currently empty but will add soon!
# fileH.write('<tr>')
# fileH.write('<td><a><img src="'+subject+'_physio.png" width=700px></a></td>')
# fileH.write('</tr>')

# Here now add a table row for each variant of the functional MRI plots
for subject in subjects:
	fileH.write('<tr>\n')
	fileH.write('<td>'+subject+'</td>\n')
	for func_label in func_labels:
		fileH.write('<td><a href='+subject+'carpet.html><img id='+func_label+subject+' src='+subject+func_label+'_'+ordering_labels[0]+'carpet.png width=400px></a></td>\n')
	fileH.write('</tr>\n')

fileH.write('<p></p><br><br>\n')
fileH.write('</table>\n')
fileH.write('<br><br><br><br>\n')
fileH.write('</center></div>\n')
fileH.write('</html>')

fileH.close()

# ------------------------HTML report-------------------------
