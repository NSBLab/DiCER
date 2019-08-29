% ------------------------------------------------------------------------------
% Linden Parkes, Brain & Mental Health Laboratory, 2017
% Kevin Aquino, BMH 2019

% ------------------------------------------------------------------------------
clear all; close all; clc
rng('default')


% ------------------------------------------------------------------------------
% Set options
% ------------------------------------------------------------------------------
Projects = {'HCP'};
WhichProject = Projects{1};
working_dir='/scratch/kg98/HCP_grayordinates_processed/';
WhichParc = 'HCP'; % 'Gordon' 'Power'

% ------------------------------------------------------------------------------
% Set project variables
% ------------------------------------------------------------------------------
switch WhichProject    
    case 'HCP'        
        % File for where the FD stats is shown
        datafile = [''];

        % first, filter out subjects not yet prepped for dbscan
        idx = [];
        % second, filter subject that have been fully dbscanned
        fltFile = 's900_unrelated_physio_same_fmrrecon.txt';
        TR = 0.72;
end

% ------------------------------------------------------------------------------
% Set parcellation
% Note, code is not setup to process multiple parcellations concurrently.
% ------------------------------------------------------------------------------
switch WhichParc
    case 'HCP'        
        ROI_Coords = dlmread('roi_HCP_MMP.txt');
end

% ------------------------------------------------------------------------------
% Load ROI coordinates
% ------------------------------------------------------------------------------
% Calculate pairwise euclidean distance
ROIDist = pdist2(ROI_Coords,ROI_Coords,'euclidean');

% Flatten distance matrix
ROIDistVec = LP_FlatMat(ROIDist);

% Calculate number of ROIs
numROIs = size(ROIDist,1);

% Calculate number of edges
numConnections = numROIs * (numROIs - 1) / 2;

% ------------------------------------------------------------------------------
% Non-imaging metadata
% ------------------------------------------------------------------------------

subject_list=dlmread('s900_unrelated_physio_same_fmrrecon.txt');
% % metadata = readtable(datafile);
% %Just a flag here because something went wrong int he table creation - damn encoding issues!
% %metadata.Properties.VariableNames{'x_ParticipantID'}='ParticipantID' 
% numGroups = length(unique(metadata.Diagnosis));
metadata=table;
metadata.ParticipantID = cell(length(subject_list),1);
for i=1:length(subject_list)
    metadata.ParticipantID{i}=num2str(subject_list(i));
end

% ------------------------------------------------------------------------------
% Filter subjects
% ------------------------------------------------------------------------------

metadata(idx,:) = [];

% fileID = fopen(fltFile); fltSubjects = textscan(fileID,'%s'); fltSubjects = fltSubjects{1};
% flt = ismember(metadata.ParticipantID,fltSubjects);
% metadata = metadata(flt,:);

% Retain only HCs for remainder of analysis
% metadata = metadata(metadata.Diagnosis == 1,:);

% idx = [2,6];
% metadata(idx,:) = [];

numSubs = size(metadata,1);

% ------------------------------------------------------------------------------
% Exclusion
% ------------------------------------------------------------------------------
% Threshold for detecting 'spikes'
fdJenkThr = 0.25;
% threshold for mean FD
fdMeanThr = 0.2;
fdGrossThr = 5;

metadata.fdJenk = cell(numSubs,1);
metadata.fdJenk_m = zeros(numSubs,1);

metadata.exclude = zeros(numSubs,1);
for i = 1:numSubs
    subject=ParticipantID{i};
    % To actually reaad the mov file
    mov = dlmread([working_dir,subject,'/',subject,'_Movements_regressors_rest.txt']);
    % Restrict just to first session for now.
    mov mov(1:1200,:);
    % mov = [conf.X, conf.Y, conf.Z, conf.RotX, conf.RotY, conf.RotZ];
    numVols = size(mov,1);

    % Get FD
    metadata.fdJenk{i} = GetFDJenk_edit(mov);
    % Calculate mean
    metadata.fdJenk_m(i) = mean(metadata.fdJenk{i});
    
    % ------------------------------------------------------------------------------
    % Stringent, multi criteria exclusion
    % ------------------------------------------------------------------------------
    % 1) Exclude on mean rms displacement
    % Calculate whether subject has suprathreshold mean movement
    % If the mean of displacement is greater than 0.2 mm (Ciric), then exclude
    if metadata.fdJenk_m(i) > fdMeanThr; x = 1; else x = 0; end 

    % 2) Exclude on proportion of spikes
    % Calculate whether subject has >20% suprathreshold spikes
    fdJenkThrPerc = round(numVols * 0.20);
    % If the number of volumes that exceed fdJenkThr are greater than %20, then exclude
    if sum(metadata.fdJenk{i} > fdJenkThr) > fdJenkThrPerc; y = 1; else y = 0; end

    % 3) Exclude on large spikes (>5mm)
    if any(metadata.fdJenk{i} > fdGrossThr); z = 1; else z = 0; end

    % If any of the above criteria are true of subject i, mark for exclusion
    if x == 1 | y == 1 | z == 1; metadata.exclude(i) = 1; else metadata.exclude(i) = 0; end
end

fprintf(1, 'Excluded %u subjects \n', sum(metadata.exclude));
metadata = metadata(~metadata.exclude,:); numSubs = size(metadata,1);



% ------------------------------------------------------------------------------
% FC
% ------------------------------------------------------------------------------
% noiseOptions = {'AROMA+2P_dbscan','AROMA+2P','AROMA+2P+GSR','24P+8P','24P+8P+GSR'}; % note these MUST match those store in columns of cfg.roiTS
% noiseOptions = {'AROMA+2P+DBSCAN','AROMA+2P','AROMA+2P+GSR','AROMA+2P+GMR'}; % note these MUST match those store in columns of cfg.roiTS
% noiseOptions = {'hpf_dbscan','hpf','hpf_gsr','hpf_aGMR'}; % note these MUST match those store in columns of cfg.roiTS

noiseOptions = {'ICA-FIX','ICA-FIX+DiCER','ICA-FIX+GMR'};

numPrePro = length(noiseOptions);

FC = zeros(numROIs,numROIs,numSubs,numPrePro);

for i = 1:numSubs
    % Load in time series data
    dbscandir = [datadir,'derivatives/fmriprep/',metadata.ParticipantID{i},'/dbscan/'];

    % Compute correlations
    for j = 1:numPrePro
        TS = dlmread([dbscandir,parcFile,'_',noiseOptions{j},'.txt']);
        FC(:,:,i,j) = corr(TS);        
        [coef,score,~,~,explained] = pca(zscore(TS).');
        first_pc(i,j) = explained(1);
        % Perform fisher z transform
        FC(:,:,i,j) = atanh(FC(:,:,i,j));
    end
end

% ------------------------------------------------------------------------------
% QC
% ------------------------------------------------------------------------------
allQC = struct('noiseOptions',noiseOptions,...
                'NaNFilter',[],...
                'QCFC',[],...
                'QCFC_PropSig_corr',[],...
                'QCFC_PropSig_unc',[],...
                'QCFC_AbsMed',[],...
                'QCFC_DistDep',[],...
                'QCFC_DistDep_Pval',[]);

for i = 1:numPrePro
% Using mFD calculated from fdJenk etc..
     [QCFC,P] = GetDistCorr(metadata.fdJenk_m,FC(:,:,:,i));

%     Do this now with SD
%    [QCFC,P] = GetDistCorr(metadata.GSSD,FC(:,:,:,i));

%     Do this now with FD from fmriprep
   % [QCFC,P] = GetDistCorr(metadata.FDfmriprep,FC(:,:,:,i));

    
    % Flatten QCFC matrix
    allQC(i).QCFC = LP_FlatMat(QCFC);
    P = LP_FlatMat(P);
    
    % Filter out NaNs:
    allQC(i).NaNFilter = ~isnan(allQC(i).QCFC);
    if ~any(allQC(i).NaNFilter)
        error('FATAL: No data left after filtering NaNs!');
    elseif any(allQC(i).NaNFilter)
        fprintf(1, '\tRemoved %u NaN samples from data \n',sum(~allQC(i).NaNFilter));
        allQC(i).QCFC = allQC(i).QCFC(allQC(i).NaNFilter);
        P = P(allQC(i).NaNFilter);
    end

    % correct p values using FDR
    P_corrected = mafdr(P,'BHFDR','true');
    allQC(i).QCFC_PropSig_corr = round(sum(P_corrected<0.05) / numel(P_corrected) * 100,2);
    allQC(i).QCFC_PropSig_unc = round(sum(P<0.05) / numel(P) * 100,2);

    % Find absolute median
    allQC(i).QCFC_AbsMed = nanmedian(abs(allQC(i).QCFC));

    % Find nodewise correlation between distance and QC-FC
    [allQC(i).QCFC_DistDep,allQC(i).QCFC_DistDep_Pval] = corr(ROIDistVec(allQC(i).NaNFilter),allQC(i).QCFC,'type','Spearman');
end
