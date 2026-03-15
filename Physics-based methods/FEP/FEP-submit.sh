#!/bin/bash

#SBATCH --mem=1G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --array 0-9

target=input
arr=(`ls $target/`)
input=${arr[$SLURM_ARRAY_TASK_ID]}
folder=$target/$input
echo $folder
FREE_ENERGY=`pwd`
echo $FREE_ENERGY

cd $folder
mkdir -p ABFE/FEP-protein
mkdir -p ABFE/FEP-water


#############################################
# ligand in complex with solvate
#############################################
 cp ions.gro topol* posre_* MOL.itp ABFE/FEP-protein
 cd ABFE/FEP-protein

for i in {0..24}; do
    sbatch $FREE_ENERGY/perturbation-gpu.sh $i $FREE_ENERGY
done


cd ../../

#############################################
# ligand in solvate
#############################################
grep 'MOL ' ions.gro > ABFE/FEP-water/mol.gro
cp MOL.itp ABFE/FEP-water/topol.top
cp posre_MOL.itp ABFE/FEP-water/

cd ABFE/FEP-water

# add parameters into topol.top
sed -i '1i\
#include "amber14sb_parmbsc1.ff/forcefield.itp"\
[ atomtypes ]\
;name   bond_type     mass     charge   ptype   sigma         epsilon       Amb\
  C3       C3          0.00000  0.00000   A     3.39967e-01   4.57730e-01 ; 1.91  0.1094\
  CF       CF          0.00000  0.00000   A     3.39967e-01   3.59824e-01 ; 1.91  0.0860\
  CG       CG          0.00000  0.00000   A     3.39967e-01   8.78640e-01 ; 1.91  0.2100\
  CH       CH          0.00000  0.00000   A     3.39967e-01   8.78640e-01 ; 1.91  0.2100\
  HN       HN          0.00000  0.00000   A     1.06908e-01   6.56888e-02 ; 0.60  0.0157\
  HX       HX          0.00000  0.00000   A     1.95998e-01   6.56888e-02 ; 1.10  0.0157\
  N1       N1          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  N4       N4          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  ND       ND          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NE       NE          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NF       NF          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NH       NH          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NJ       NJ          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NL       NL          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NN       NN          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  NO       NO          0.00000  0.00000   A     3.25000e-01   7.11280e-01 ; 1.82  0.1700\
  OQ       OQ          0.00000  0.00000   A     3.00001e-01   7.11280e-01 ; 1.68  0.1700\
  S6       S6          0.00000  0.00000   A     3.56359e-01   1.04600e+00 ; 2.00  0.2500\
  SS       SS          0.00000  0.00000   A     3.56359e-01   1.04600e+00 ; 2.00  0.2500\
  SX       SX          0.00000  0.00000   A     3.56359e-01   1.04600e+00 ; 2.00  0.2500\
  SY       SY          0.00000  0.00000   A     3.56359e-01   1.04600e+00 ; 2.00  0.2500\
' topol.top
echo '#include "amber14sb_parmbsc1.ff/tip3p.itp"' >> topol.top
echo '#include "amber14sb_parmbsc1.ff/ions.itp"' >> topol.top
echo '[ system ]' >> topol.top
echo 'MOL in water'  >> topol.top
echo '[ molecules ]' >> topol.top
echo '; Compound        nmols' >> topol.top
echo 'MOL                 1' >> topol.top

# add box size and atom numbers into mol.gro
b=`(wc -l mol.gro)`
lineb=`(echo $b | awk '{print$1}')`
sed -i '1s/^/ligand structure\n/' mol.gro
sed -i '2s/^/'$lineb'\n/' mol.gro
echo '0.00 0.00 0.00' >> mol.gro

module load gromacs

mdpfilepath=$FREE_ENERGY/MDPfiles/
gmx_mpi editconf -f mol.gro -o box.gro -bt cubic -c -d 1.0
gmx_mpi solvate -cp box.gro -cs spc216.gro -o solvated.gro -p topol.top
gmx_mpi grompp -f $mdpfilepath/ions.mdp -c solvated.gro -p topol.top -o ions.tpr 
echo SOL | gmx_mpi genion -s ions.tpr -p topol.top -pname NA -nname CL -neutral -o ions.gro -conc 0.15
rm box.gro ions.tpr solvated.gro mdout.mdp \#topol.top.*


for i in {0..24}; do
    sbatch $FREE_ENERGY/perturbation-cpu.sh $i $FREE_ENERGY
done

