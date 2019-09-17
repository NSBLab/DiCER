#!/bin/bash 

#SBATCH --job-name=level3_HCP
#SBATCH --account=hf49
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=300:00
#SBATCH --mail-user=kevin.aquino@monash.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=12000
#SBATCH -A hf49

module load connectome

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

#SubjectList="183034 185442 186141 186444 187345 188448 188549 188751 189450 192035 195849 198249 198855 199453 199958 200008 200311 201515 204319 204521 206222 207123 214524 212419 213421"

#SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 112920 113922 116524 118124 118528 119126 121416 122822 124826 127630 129129"
#SubjectList="100206 100610 102311 106016 107321 107422 108222 109830 112112 112314 112920 116524 118528 119126 121416 122822 124826 129129"
#SubjectList="100206 100610 101006 101309 101915 102311 106016 107321 107422 108222 109830 112112 112314 112920 116524 118528 119126 121416 122822 124826 129129 129634 130316 130417 131217 131823 132017 133019 134021 134223 134425 134728 135528 135730 136732 137229 137633 139233 139839 140117 141119 144125 144731 146129 146432 147030 148133 149842 150625 153227 154229 154532 154734 155635 155938 157942 159138 159340 160830 162733 163836 164030 164939 167238 169949 171633 172938 173435 173536 173738 173940 175338 175742 176037 178950 181232 181636 182436 185442 186141 186444 188448 188751 189450 191033 192035 192843 194645 194746 195445 195950 197348 199453 199958 200008 203418 203923 204521 204622 206222"i
#SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 113922 116524 118124 118528 119126 121416 122822 124826 127630 129129"
#SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 112920 113922 116524 118124 118528 119126 121416 122822 124826 127630 129129 129634 130316 130417 131217 131823 132017 133019 134021 134223 134425 134728 135528 135730 136732 137633 139233 139839 141119 144125 144731 146129 146533 146937 147030 148133 149236 149842 150625 150928 152831 153227 154229 154532 154734 154835 154936 155635 155938 157942 159138 159340 159441 160830 163331 163836 164030 164939 167238 168240 169949 170631 171633 172938 173435 173536 173738 173839 173940 175035 175237 175338 175742 176037 178950 179346 180129 181131 181232 181636 182436 183034 185442"
#SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 112920 113922 116524 118124 118528 119126 121416 122822 124826 127630 129129 129634 130316 130417 131217 131823 132017 133019 134021 134223 134425 134728 135528 135730 136732 137633 139233 139839 140117 141119 141826 144125 144731 146129 146432 146533 146937 147030 148133 149236 149842 150625 150928 152831 153227 154229 154532 154734 154835 154936 155635 155938 157942 159138 159340 159441 160830 162733 163331 163836 164030 168240 169949 170631 171633 172938 173435 173536 173738 173839 173940 175035 175237 175338 175742 176037 178950 179346 180129 181131 181232 181636 182436 "
SubjectList="100206 100610 101006 101309 101915 102311 102513 106016 107321 107422 108121 108222 109830 110007 110613 112112 112314 112920 113922 116524 118124 118528 119126 121416 122822 124826 127630 129129 129634 130316 130417 131217 131823 132017 133019 134021 134425 134728 135528 135730 136732 139233 139839 141119 141826 144125 144731 146129 146533 146937 147030 148133 149236 149842 150625 150928 152831 153227 154229 154532 154734 154835 155635 155938 157942 159138 159340 159441 160830 163331 163836 164030 168240 169949 171633 172938 173536 173839 173940 175035 175338 178950 179346 180129 181131 181232 181636 183034 185442 186444 188448 188549 189450 191033 192035 192136 192843 194746 195445 197348"
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

#AnalysisName="Group_25_DiCER"   #Used as initial prefix in some file naming
ResultsFolder="/scratch/kg98/HCP_grayordinates_processed/${AnalysisName}" #Here, ResultsFolder named using AnalysisName, 
                                                     #although that doesn't have to be the case
#ResultsFolder="/home/kaqu0001/projects/${AnalysisName}"

#LevelTwoTaskList="tfMRI_EMOTION tfMRI_GAMBLING tfMRI_LANGUAGE tfMRI_MOTOR tfMRI_RELATIONAL tfMRI_SOCIAL tfMRI_WM" ##List of the tasks to analyze
#LevelTwoTaskList="tfMRI_MOTOR"

ContrastList="ALL" #USE "ALL" for analysing all the Lev2 contrasts
# N.B. Currently, ContrastList applies to all tasks in the LevelTwoTaskList
# i.e., no mechanism for different ContrastLists for different tasks.
# (However, could potentially implement that into the looping code below
# if ContrastList was set up as an array of lists).


########## REVIEW THE FOLLOWING VARIABLES (YOU LIKELY DON'T NEED TO CHANGE THESE) ###############
# StudyFolder="/scratch/kg98/HCP_grayordinates_processed_temporary/"
#StudyFolder="DiCER_taskResults"
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
