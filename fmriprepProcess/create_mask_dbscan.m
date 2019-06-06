% This here generates the masks needed and it also generates the ordering, right now this is all in matlab will phase into the python version of all of this soon.

% Take environment variables -- right now specific to MASSIVE but will change this soon.

addpath(['/scratch/kg98/kevo/GSR_data']);
setenv('TMPDIR',['~/']);
addpath([getenv('FREESURFER_HOME'),'/matlab']);
func=getenv('func');
gm_prob=getenv('gm_prob_epi');
save_mask=getenv('gm_dbscan');
brain_mask=getenv('mask_epi');
dtissue=getenv('dtissue_epi_masked');
confounds=getenv('confounds'); 


% Here load up the confounds table
conf=readtable(confounds,'FILETYPE','text');

% Here we take the niftis, and read them
gm_prob=MRIread(gm_prob);
func=MRIread(func);


% Have to replace these steps in python and fslmaths steps (to make it more accessible)

% ------------------------------ Restrictive masks ------------------------------
% Now make a restrictive mask using 0.5 on the interpolated epi mask
mask_strict = gm_prob;
mask_strict.vol(mask_strict.vol(:)<0.5) = 0;
mask = find(mask_strict.vol(:));

% Here have to threshold away voxels that have low mean signal intensity
% (for a robust metric)
time_series = reshape(func.vol,prod(func.volsize),func.nframes);
time_series = time_series(mask,:);
mean_series = mean(time_series,2);
mask_strict.vol(mask) = mean_series/max(mean_series(:));

% Here have a mask that only looks at voxels > 0.3 in the threshold
mask_values = mean_series/max(mean_series(:));
mask_30 = find(mask_values>=0.3);
mask_strict.vol(mask(mask_30)) = 1;
mask_strict.vol(mask_strict.vol<1) = 0;

% Now write up the mask
MRIwrite(mask_strict,save_mask);


% ------------------------------ Restrictive masks ------------------------------



% Can do the bottom using AFNI:

% Using something like the following:
% 3dTproject -input sub-10448_task-rest_bold_space-MNI152NLin2009cAsym_variant-AROMAnonaggr+2P_preproc.nii.gz -prefix ppp -passband 0.005 0.2
% Then using 3dcopy to make the afni file a nifti
% 3dcopy ppp+tlrc testing.nii.gz
% Then also have to apply a mask to it -- most likely done either at this input stage or we can do it at a later stage, not sure yet.

% This does it all in one hit it looks like it works
% ------------------------------ Temporal processing ------------------------------
% After the mask has been written up we have to then do some processing on
% the voxels, high pass filtering and taking nans out
clear time_series
time_series = reshape(func.vol,prod(func.volsize),func.nframes);

%now take NaNs out of the time series and set them to zero
mean_ts_all = mean(time_series,1);
nans_inds = find(isnan(mean_ts_all));
time_series(nans_inds,:) = 0;

%================= Now perform a linear detrend of the data
time_series = detrend(time_series.').';

% After the time series has been detrended lets perform high pass filtering
addpath(genpath('/home/kaqu0001/projects/GSRSimulation'));
TR=func.tr;
if(TR>10)
	%little hack to check if TR is in ms or in s.
	TR=TR/1000;
end
filteredData = rest_IdealFilter(time_series',TR,[0.005,0]);
time_series = filteredData';

%now take NaNs out of the time series and set them to zero (again in case
%something has happened)
mean_ts_all = mean(time_series,1);
nans_inds = find(isnan(mean_ts_all));
time_series(nans_inds,:) = 0;


% Now reading in the brain mask
mask_brain = MRIread(brain_mask);

% Currently setting a threshold of 0.2, quite liberal at the moment - might have to refine? 
non_brain = find(mask_brain.vol(:)<0.2);
time_series(non_brain,:) = 0;
% ------------------------------ Temporal processing ------------------------------


% -------------------------------  GS ordering ------------------------------------


% Ordering masked out time series -- what DBSCAN is using
% Now take the grey matter time series and find an ordering
mask = find(mask_strict.vol);
grey_time_series = zscore(time_series(mask,:),[],2);
gs_gmt = mean(grey_time_series,1);
gscorr = corr(grey_time_series.',gs_gmt.');
[~,order]=sort(gscorr);
order_struct = mask_strict;
order_struct.vol(mask) = order;

% ======= Now do the ordering for each sub-tissue type
% Load in dtissue 
% - do the ordering per tissue
% Here set it up:

tissue_components = MRIread(dtissue);
% Now we add the mask made before and set this as the new GM mask at a higher level of 4 to indicate this is what DBSCAN is using!
tissue_components.vol(mask) = 4;
MRIwrite(tissue_components,dtissue);
all_vox = find(tissue_components.vol);

all_vox_types = tissue_components.vol(:);
% remaining_voxels = setdiff(all_vox,mask);

% Go through each tissue type, calculate the gs ordering and then save it (see what happens to be honest)
tissue_order = zeros(size(tissue_components.vol));
for tissue_inds=1:4,
	voxel_type_inds = find(all_vox_types==tissue_inds);
	% if(tissue_inds==2)
	% 	voxel_type_inds = setdiff(voxel_type_inds,mask);
	% end
	time_series_type = zscore(time_series(voxel_type_inds,:),[],2);
	gs_vt = mean(time_series_type,1);
	gscorr = corr(time_series_type.',gs_vt.');
	[~,order_tv]=sort(gscorr);	
	tissue_order(voxel_type_inds) = order_tv-1;
end

tissue_components.vol = tissue_order;

% -------------------------------  GS ordering ------------------------------------


% -------------------------------  Writing NIFTIs ------------------------------------

% Now write the files for the functional input:
[~,file,fmt] = fileparts(func.fspec);
% Ideally saving it into dbscan's folder
[pth,~,~] = fileparts(save_mask);
func.fspec = [pth,'/',file,fmt];

dbscan_file = [func.fspec(1:end-7),'_detrended_hpf.nii.gz'];
dbscan_input_struct = func;
dbscan_input_struct.vol = reshape(time_series,func.volsize(1),func.volsize(2),func.volsize(3),func.nframes);
MRIwrite(dbscan_input_struct,dbscan_file);

% Here do GMR -- grey matter regression
mgs = RegressNoiseSignal(time_series,gs_gmt);
gs_file = [func.fspec(1:end-7),'_detrended_hpf_GMR.nii.gz'];
gs_input_struct = func;
gs_input_struct.vol = reshape(mgs,func.volsize(1),func.volsize(2),func.volsize(3),func.nframes);
MRIwrite(gs_input_struct,gs_file);


% Here do GSR using GSR from up to this point instead.
mask_ts = find(time_series(:,1) ~= 0);
GlobalSignal = nanmean(time_series(mask_ts,:));
gsr_ts = RegressNoiseSignal(time_series,GlobalSignal);
gs_file = [func.fspec(1:end-7),'_detrended_hpf_gsr_post.nii.gz'];
gs_input_struct = func;
gs_input_struct.vol = reshape(gsr_ts,func.volsize(1),func.volsize(2),func.volsize(3),func.nframes);
MRIwrite(gs_input_struct,gs_file);




% Here do GSR -- global signal regression -- using the GS derived from the processed, but only applying hpf and detrending after.

time_series = reshape(func.vol,prod(func.volsize),func.nframes);
time_series(nans_inds,:) = 0;
time_series(non_brain,:) = 0;

% Resetting the time series

GlobalSignal = (zscore(conf.GlobalSignal)).';
time_series = RegressNoiseSignal(time_series,GlobalSignal);
time_series = detrend(time_series.').';
filteredData = rest_IdealFilter(time_series',TR,[0.005,0]);
time_series = filteredData';

gsr_ts = time_series;

gs_file = [func.fspec(1:end-7),'_detrended_hpf_gsr.nii.gz'];
gs_input_struct = func;
gs_input_struct.vol = reshape(gsr_ts,func.volsize(1),func.volsize(2),func.volsize(3),func.nframes);
MRIwrite(gs_input_struct,gs_file);



% Now write it for the ordering:
order_file = [save_mask(1:end-7),'_gsordering.nii.gz'];
MRIwrite(order_struct,order_file);

% Now write it for the tissue order:
order_file = [save_mask(1:end-7),'_gsordering_tissue.nii.gz'];
MRIwrite(tissue_components,order_file);

% -------------------------------  Writing NIFTIs ------------------------------------


% Get rid of this section, we don't need to copy these over any more, it is not needed -- working entirely within the BIDS formatting system

% system(['cp ',save_mask,' /scratch/kg98/kevo/GSR_data/fmriprep/']);
% system(['cp ',order_file,' /scratch/kg98/kevo/GSR_data/fmriprep/']);
% system(['cp ',dbscan_file,' /scratch/kg98/kevo/GSR_data/fmriprep/']);
