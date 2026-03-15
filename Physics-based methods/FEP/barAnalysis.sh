#!/bin/bash

#SBATCH --mem=1G
#SBATCH --account dkhf3-lab
#SBATCH -p dkhf3-lab
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --array 0-9

module load gromacs
class=input
arr=(`ls $class/`)
input=${arr[$SLURM_ARRAY_TASK_ID]}
folder=$class/$input/ABFE/FEP-protein

#input=$1
#folder=$input/FEP-protein
echo "$input was found to calculate FEP."
echo "working folder: $folder"


	cd $folder
	count1=(`grep Performance Lambda_*/Production_MD/md*.log | wc -l`)
	echo "there are $count1 lambda in protein"
	if [ "$count1" -eq 25 ]; then
		rm slurm-*.out
		gmx_mpi bar -f Lambda_*/P*/md*.xvg -o -oi -b 0 -e 5000  >& dG-5ns.out
		rm \#bar*
	fi
	
	cd ../FEP-water/
	count2=(`grep Performance Lambda_*/Production_MD/md*.log | wc -l`)
	echo "there are $count2 lambda in water"
	if [ "$count2" -eq 25 ]; then
		rm slurm-*.out
		gmx_mpi bar -f Lambda_*/P*/md*.xvg -o -oi -b 0 -e 5000  >& dG-5ns.out
		rm \#bar*
	fi
	
