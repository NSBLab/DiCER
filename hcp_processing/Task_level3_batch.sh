#!/bin/bash 

# Requirements for this script
#  installed versions of: FSL (version 5.0.6 or later)
#  environment: FSLDIR , HCPPIPEDIR , CARET7DIR

### Set up pipeline environment variables and software ###
EnvironmentScript="/home/kaqu0001/HCPpipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
#. ${EnvironmentScript}  ## Sourcing of full EnvironmentScript not needed (assuming FSLDIR already in PATH)


########## CHANGE THE FOLLOWING VARIABLES FOR YOUR STUDY ###############

### USE ONLY ONE OF THE FOLLOWING TWO METHODS TO SPECIFY YOUR SUBJECT LIST
### REMOVE COMMENTS FROM USED METHOD, KEEP UNUSED METHOD COMMENTED OUT
### NOTE THAT the order your subject list MUST MATCH the order in your LevelThreeFsf
### if you are using any subject specific covariates (i.e., doing anything more complicated
### than just a single group mean model).

##(1) Paste your space-delimited subject list here
## The SubjectList can be space delimited or using "@" instead of spaces. 

SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 112920 113922 116524 118124 118528 119126 121416 122822"

##(2) Read your text file into a space-delimited list 
## First you must make your subject list into a single-column text file without headers.

#subjfile=/PATH/TO/FILE
#SubjectList=`cat $subjfile | ${HCPPIPEDIR_Global}/change2unix.pl | cut -d',' -f1 | tr "\n" " " | sed -e 's/ *$//g'`

### Additional variables to set ###
LevelThreeFsf="/home/kaqu0001/projects/DiCER/hcp_processing/level3_group_stats.fsf" #Used to compute the design matrix

AnalysisType="GRAYORD" #GRAYORD, VOLUME, or BOTH
## CAUTION: VOLUME analysis involves unconstrained volumetric blurring of the data.
## GRAYORD (grayordinate) is faster, less biased, and more sensitive.
## (Grayordinates results do not use unconstrained volumetric blurring).

AnalysisName="Group_50_emotion_DiCER"   #Used as initial prefix in some file naming
ResultsFolder="/scratch/kg98/HCP_grayordinates_processed/${AnalysisName}" #Here, ResultsFolder named using AnalysisName, 
                                                     #although that doesn't have to be the case
LevelTwoTaskList="tfMRI_EMOTION" ##List of the tasks to analyze
ContrastList="1" #USE "ALL" for analysing all the Lev2 contrasts
# N.B. Currently, ContrastList applies to all tasks in the LevelTwoTaskList
# i.e., no mechanism for different ContrastLists for different tasks.
# (However, could potentially implement that into the looping code below
# if ContrastList was set up as an array of lists).


########## REVIEW THE FOLLOWING VARIABLES (YOU LIKELY DON'T NEED TO CHANGE THESE) ###############
# StudyFolder="/scratch/kg98/HCP_grayordinates_processed_temporary/"
StudyFolder="DiCER_taskResults"
SmoothingList="2" #For setting different final smoothings.  2 is no additional smoothing.
TemporalFilter="200" #Use 2000 for linear detrend
RegNames="MSMAll" #Set to MSM all which is the state of the art at the moment
############################


########################################## INPUTS ########################################## 

# Assumes Lev2 analysis from the HCP Task Analysis Pipeline has been run (and outputs exist) 
# for each subject and task specified in the lists above

######################################### DO WORK ##########################################


###Nothing should need changing beyond this point
# Log the originating call
echo "$@"

SubjectList=`echo $SubjectList | sed 's/ /@/g'`
ContrastList=`echo $ContrastList | sed 's/ /@/g'`
for RegName in $RegNames ; do
  i=1
  for LevelTwofMRIName in $LevelTwoTaskList ; do
    #LevelTwofsfName=`echo $LevelTwoFSFList | cut -d " " -f $i`
    LevelTwofsfName=${LevelTwofMRIName}
    for FinalSmoothingFWHM in $SmoothingList ; do

       sh TaskfMRILevel3.sh \
	--path=$StudyFolder \
	--subjectlist=$SubjectList \
	--resultsfolder=$ResultsFolder \
	--analysisname=$AnalysisName \
	--lvl3fsf=$LevelThreeFsf \
	--lvl2task=$LevelTwofMRIName \
	--lvl2fsf=$LevelTwofsfName \
	--finalsmoothingFWHM=$FinalSmoothingFWHM \
	--temporalfilter=$TemporalFilter \
	--regname=$RegName \
	--analysistype=$AnalysisType \
	--contrastlist=$ContrastList  
	
# The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

        echo "set -- --path=$StudyFolder \
	--subjectlist=$SubjectList \
	--resultsfolder=$ResultsFolder \
	--analysisname=$AnalysisName \
	--lvl3fsf=$LevelThreeFsf \
	--lvl2task=$LevelTwofMRIName \
	--lvl2fsf=$LevelTwofsfName \
	--finalsmoothingFWHM=$FinalSmoothingFWHM \
	--temporalfilter=$TemporalFilter \
	--regname=$RegName \
	--analysistype=$AnalysisType \
	--contrastlist=$ContrastList" 

#	echo ". ${EnvironmentScript}"

    done
    i=$(($i+1))
  done
done