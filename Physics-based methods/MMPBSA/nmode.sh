#!/bin/bash

#SBATCH --mem=10G
#SBATCH --job-name=MMPBSA-IE
#SBATCH --time=2-00:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8

#######################
module load conda
eval "$(conda shell.bash hook)"
conda activate gmxMMPBSA
#######################
#
# entropy - IE
#
echo "--- MM/PB(GB)SA calculation with entropy IE---"
mpirun -np 8 gmx_MMPBSA MPI -O -i ../../mmpbsa-nmode.in -cs ../md.tpr -ci ../index.ndx -cg 1 13 -ct ../md_pbsa.xtc -lm ../ligand.mol2 -o MMPBSA_BFE_nmode.dat -eo MMPBSA_BFE_nmode.csv
