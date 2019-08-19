#!/bin/env bash

#SBATCH --job-name=DiCER
#SBATCH --account=kg98
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=600:00
#SBATCH --mail-user=kevin.aquino@monash.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=32000
#SBATCH -A kg98
#SBATCH --array=1


SUBJECT_LIST="/home/kaqu0001/projects/DiCER/hcp_processing/s900_unrelated_physio_same_fmrrecon.txt"

export subject=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SUBJECT_LIST})
echo -e "\t\t\t --------------------------- "
echo -e "\t\t\t ----- ${SLURM_ARRAY_TASK_ID} ${subject} ----- "
echo -e "\t\t\t --------------------------- \n"

#Load connectome module
module load connectome

export Subjlist=$subject
export StudyFolder=/scratch/kg98/HCP_grayordinates_processed_temporary/

sh /home/kaqu0001/HCPpipelines/Examples/Scripts/TaskfMRIAnalysisBatch.sh --runlocal
