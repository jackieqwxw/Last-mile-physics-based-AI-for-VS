#!/bin/bash

#SBATCH --mem=1G
#SBATCH --job-name=MD
#SBATCH --array 0-9
#SBATCH -p gpu
#SBATCH --gres gpu:A100:1
#SBATCH --time=8:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8

module load gromacs/2022.5_gcc_9.5.0_openmpi_4.1.5_cuda

# upload all prepared proteins into prepared_proteins/ dir.
arr=(`ls prepared_proteins/*.pdb`)
input=${arr[$SLURM_ARRAY_TASK_ID]}
prefix=(`echo "$input" | awk -F '/' '{print$2}' | awk -F '.' '{print$1}'`)
## Set up AMBER14SB ff enviroment variable, otherwise copy amber14sb_parmbsc1.ff to working dir.
#cp -r amber14sb_parmbsc1.ff $prefix
cp ../LigPara/$prefix .
cd $prefix
## Here '7' to choose ff14SB.
echo 7 | gmx_mpi pdb2gmx -f ../$input -o prot.gro -water tip3p -ignh
echo 2 | gmx_mpi genrestr -f MOL_GMX.gro -o posre_MOL.itp -fc 1000 1000 1000	 

sed -i '/^\[ *moleculetype *\]/i #include "MOL.itp"\n' topol.top
echo 'MOL                 1' >> topol.top

#------------------------------------------------
# Combine ligand and protein into one com.gro file 
#------------------------------------------------
sed "s|pdbid|$prefix|g" ../CombineProtLigMD.py > CombineProtLigMD_$prefix\.py 
chmod +x CombineProtLigMD_$prefix\.py
./CombineProtLigMD_$prefix\.py
rm ./CombineProtLigMD_$prefix\.py

echo '========start MD simulations========'
echo $folder
path=../MD-gmx-mdp
#========start MD simulations============
gmx_mpi editconf -f com.gro -o newbox.gro -c -d 1.0 -bt cubic
gmx_mpi solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top
gmx_mpi grompp -f  $path/ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 1
echo SOL | gmx_mpi genion -s ions.tpr -p topol.top -pname NA -nname CL -neutral -o ions.gro -conc 0.15
gmx_mpi grompp -f  $path/minim.mdp -c ions.gro -p topol.top -o em0.tpr -maxwarn 1
gmx_mpi mdrun -v -deffnm em0
# create 'protein + ligand' group
gmx_mpi make_ndx -f em0.gro <<EOF
1 | 13
q
EOF
gmx_mpi grompp -f  $path/nvt0.mdp -c em0.gro -r em0.gro -p topol.top -o nvt0.tpr -maxwarn 1 -n index.ndx
gmx_mpi mdrun -v -deffnm nvt0 -update gpu -nb gpu -bonded gpu -pme gpu
gmx_mpi grompp -f  $path/npt0.mdp -c nvt0.gro -r nvt0.gro -t nvt0.cpt -p topol.top -o npt0.tpr -maxwarn 1 -n index.ndx
gmx_mpi mdrun -v -deffnm npt0 -update gpu -nb gpu -bonded gpu -pme gpu
gmx_mpi grompp -f  $path/md.mdp -c npt0.gro -t npt0.cpt -p topol.top -o md.tpr -maxwarn 1 -n index.ndx
gmx_mpi mdrun -v -deffnm md -update gpu -nb gpu -bonded gpu -pme gpu
#========end MD simulations============
echo '========end MD simulations========'



#--- data processing post-MD ---
echo Protein_MOL 0 | gmx_mpi trjconv -s md.tpr -f md.xtc -o md_nopbc.xtc -pbc mol -center -n index.ndx
# RMSD Backbone and Ligand
echo 4 1 |  gmx_mpi rms -s em0.tpr -f md_nopbc.xtc -o rmsd_prot -tu ns
echo MOL MOL |  gmx_mpi rms -s em0.tpr -f md_nopbc.xtc -o rmsd_lig -tu ns
rm \#* step* slurm*out
#rm em0.trr em0.log em0.edr mdout.mdp
#rm nvt0.xtc nvt0.log nvt0.edr nvt0.cpt
#rm npt0.xtc npt0.log npt0.edr npt0.cpt




echo "--- MM/PB(GB)SA calculation ---"
#---- MMPBSA calculation ----
echo Protein_MOL Protein_MOL | gmx_mpi trjconv -s md.tpr -f md_nopbc.xtc -o md_pbsa.xtc -b 4000 -dt 1 -n index.ndx -fit rot+trans
rm md_nopbc.xtc
# generate ligand.mol2
gmx_mpi editconf -f com.gro -o com.pdb
grep MOL com.pdb | grep -v TITLE > lig.pdb 
python3 ../pdb2mol2.py
rm com.pdb lig.pdb
mkdir bfe-withEntropy-IE
mkdir bfe-withEntropy-nmode
#
# entropy - IE
#
echo "--- MM/PB(GB)SA calculation with entropy IE---"
cd bfe-withEntropy-IE
sbatch ../../mmpbsa-ie.sh
#
# entropy - nmode
#
echo "--- MM/PB(GB)SA calculation with entropy normal mode analysis (NMA)---"
cd ../bfe-withEntropy-nmode
sbatch ../../nmode.sh
echo "---Calculation Completed---"
