# carpetPlot.py
#
# Kevin Aquino
# Brain and Mental Health Research Hub
# 2018
#
# This is a python script to generate a carpet plot from given argeuments.

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning) 

# Run with command line arguments precisely when called directly
# (rather than when imported)

def main(raw_args=None):

	# Parse in inputs
	from argparse import ArgumentParser
	parser = ArgumentParser(epilog="carpetplot.py -- A function to generate carpet plots by taking in the grey matter mask with a given ordering. Kevin Aquino 2018 BMH")
	parser.add_argument("-f", dest="func",
		help="functional MRI time series", metavar="fMRI")
	parser.add_argument("-ot", dest="tissue_ordering", default="none",
		help="The ordering of the time series per tissue type", metavar="ord")
	parser.add_argument("-s", dest="subject",
		help="The subject", metavar="subject_label")
	parser.add_argument("-ts", dest="dtissue",
		help="tisue segmentation", metavar="dtissue.nii.gz")
	parser.add_argument("-l", dest="label",
		help="Label for the title and used for", metavar="label_")
	parser.add_argument("-d", dest="folder",
		help="folder for to save the carpet plot", metavar="saving_dir")
	parser.add_argument("-axis", dest="axisLim", default="1.2",
		help="The axis limits for the carpet plots", metavar="VAL")

	# import pdb;pdb.set_trace()
	# Here we are parsing the arguments
	args = parser.parse_args(raw_args)

	# Setting the arguments
	func 	= args.func
	subject = args.subject
	label 	= args.label
	folder 	= args.folder
	dtissue = args.dtissue
	axisLim = float(args.axisLim)
	tissue_ordering = args.tissue_ordering

	# First off import all the bits:
	from matplotlib import rcParams
	rcParams['font.family'] = 'sans-serif'
	rcParams['font.sans-serif'] = ['Arial']
	# Setting the text to arial as the default matplotlib test is fugly
	# This is the nibabel package to load in the NIFTI format
	import nibabel as nib
	# This is the usual suspect to import plotting routines
	import matplotlib.pyplot as plt
	# This is just the numerical package:
	import numpy as np
	# Import plotting tools
	from matplotlib import gridspec
	# Import the stats module
	from scipy import stats
	# Import the little fmri_tools we need
	import sys,os
	sys.path.insert(1, os.path.join(sys.path[0], '..'))
	from utils import fMRI_in_out as mrutils

	# -------------------------------------------- Function defintions--------------------------------------------
	def carpet_visualize(tser):
	   """ Function to display row of image slices """
	   # Here set up the figure
	   plt.figure(num=1,figsize=(5, 3.5), dpi=300)
	   # Zscore the ts
	   tser = stats.zscore(tser,axis=1,ddof=1)
	   # Here show the carpet plot in all its glory	   
	   plt.imshow(tser,cmap="gray", origin="lower", extent=[0,tser.shape[1],0,1], aspect=100, vmin=-axisLim, vmax=axisLim)

	def segmented_plot(tissue,mask_voxels,time_series,ordering):
		
		# Will have to look GM time series without the inclusion masks
		CSF_ind	=1
		GMI_ind	=2
		WM_ind	=3
		GM_dbscan = 4

		GM_vox=np.squeeze(np.where(tissue==GMI_ind))
		GMdbscan_vox=np.squeeze(np.where(tissue==GM_dbscan))

		# Get all the voxels
		# GM_vox=np.setdiff1d(GM_seg,mask_voxels[0])
		WM_vox=np.squeeze(np.where(tissue==WM_ind))
		CSF_vox=np.squeeze(np.where(tissue==CSF_ind))

		# Probably have to get rid of nans/zeros etc -- better not done here, this here is just to visualize	
		gm_time_series = stats.zscore(time_series[GM_vox,:],axis=1,ddof=1)
		gm_dbscan_time_series = stats.zscore(time_series[GMdbscan_vox,:],axis=1,ddof=1)
		wm_time_series = stats.zscore(time_series[WM_vox,:],axis=1,ddof=1)
		csf_time_series = stats.zscore(time_series[CSF_vox,:],axis=1,ddof=1)
		# Now ordering it all have to do it one by one:
		# Get ordering for each tissue:

		if ordering != "none":
			# import pdb; pdb.set_trace()
			ordering_data,dims = mrutils.import_nifti(ordering)
			# Typecast into ints		
			gm_order  = ordering_data[GM_vox].astype(int)
			# import pdb; pdb.set_trace()
			gmdbscan_order  = ordering_data[GMdbscan_vox].astype(int)
			wm_order  = ordering_data[WM_vox].astype(int)
			csf_order = ordering_data[CSF_vox].astype(int)
			gm_time_series = gm_time_series[gm_order,:]
			wm_time_series = wm_time_series[wm_order,:]
			csf_time_series = csf_time_series[csf_order,:]
			gm_dbscan_time_series = gm_dbscan_time_series[gmdbscan_order,:]

		# Plotting here, done independetly of above
		ts_all=np.vstack((gm_dbscan_time_series,gm_time_series,wm_time_series,csf_time_series))
		label_stack=np.vstack((1*np.ones((len(GMdbscan_vox),1)),2*np.ones((len(GM_vox),1)),3*np.ones((len(WM_vox),1)),4*np.ones((len(CSF_vox),1))))
		label_stack = np.hstack((label_stack,label_stack))


		fig = plt.figure(figsize=(5, 3.5), dpi=300) 
		gs = gridspec.GridSpec(1, 2, width_ratios=[1, 50], wspace=0) 
		ax0 = plt.subplot(gs[0])
		ax1 = plt.subplot(gs[1])
		ax0.imshow(label_stack,cmap='hot',origin="lower",aspect='auto',vmax=4,vmin=1)
		ax1.imshow(ts_all,cmap="gray", origin="lower",extent=[0,time_series.shape[1],0,1], aspect='auto', vmin=-axisLim,vmax=axisLim)
		ax0.spines["left"].set_visible(False)
		ax0.spines["bottom"].set_color('none')
		ax0.spines["bottom"].set_visible(False)
		ax0.get_xaxis().set_visible(False)
		ax0.get_yaxis().set_visible(False)
		ax1.get_yaxis().set_visible(False)	
	# ---------------------------------------------------------------------------------------------------------------

	# Now run the code to import the time series, then use the ordering and generate the plots
	time_series,dims	= mrutils.import_nifti(func)
	tissue,dims 		= mrutils.import_nifti(dtissue)

	# Now after it has been imported, show the time series
	mask_voxels 	= np.squeeze(np.where(tissue==4))

	# Get the grey matter time series
	grey_time_series = time_series[mask_voxels,:]

	# import pdb; pdb.set_trace()
	if tissue_ordering != "none":
		# If you have ordering data:
		ordering_data,dims 	= mrutils.import_nifti(tissue_ordering)
		ordering_data 		= np.squeeze(ordering_data[mask_voxels].astype(int))	
		grey_time_series = stats.zscore(grey_time_series[ordering_data,:],axis=1,ddof=1)


	# The last bit here is the visualize the time series using the function defined above, this is a complete case
	carpet_visualize(grey_time_series)



	# Now adding labelling for the figure as well as a nice handle for the saved image
	title = subject+' '+label+' GMT'
	savingName = folder+subject+label+'carpet.png'

	# Here setting up the final bits for the plotting output.
	frame = plt.gca()
	frame.axes.yaxis.set_ticklabels([])
	plt.xlabel('Frames')
	plt.suptitle(title)
	plt.savefig(savingName)
	plt.clf()


	title = subject+' '+label+' tissue_GMT'
	savingName = folder+subject+label+'tissue_carpet.png'

	# import pdb; pdb.set_trace()
	segmented_plot(tissue,mask_voxels,time_series,tissue_ordering)
	frame = plt.gca()
	frame.axes.yaxis.set_ticklabels([])
	plt.xlabel('Frames')
	plt.suptitle(title)
	plt.savefig(savingName)
	plt.clf()



if __name__ == '__main__':
    main()