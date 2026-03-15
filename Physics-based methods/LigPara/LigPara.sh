#!/bin/bash
#SBATCH -A dkhf3-lab
#SBATCH -p dkhf3-lab
#SBATCH -t 1-00:00:00
#SBATCH --cpus-per-task=16

# activate obabel envioment
module load miniconda3
eval "$(conda shell.bash hook)"
conda activate obabel
## Load the Gaussian Module
module load gaussian/16-C.02-avx2
mkdir  /local/scratch/xwpnp
## Load AMBERTools
module load amber

## variable
finput=$1 # inputfile: PDBbind_db_ligands.sdf
charge=$2 # charge of every small molecule. 

# Convert SDF file to individual XYZ files
obabel -isdf $finput -oxyz -Olig.xyz -m

# Count the number of ligands in the SDF file
fnum=$(grep -c 'M  END' $finput)

# Loop through each ligand and process it
for ((i=1; i<=fnum; i++))
do
  ############################
  ## Part1: Calculate ESP   ##
  ############################
  file=lig$i.xyz
  new=$(head -n 2 "$file" | tail -n 1 | awk -F '_' '{print $1}')
  # Rename the ligand file with the extracted ligand ID
  mv "$file" "${new}.xyz"
  echo "Start to processing the molecule ${new} at $(date '+%Y-%m-%d %H:%M:%S')"

  # Generate Gaussian input file
  sed -n '3,$p' "${new}.xyz" > "${new}_tmp"
  {
    echo "%nproc=16"
    echo "%mem=1GB"
    echo "%chk=esp-tmp-${new}.chk"
    echo "#p hf/6-31G* pop=mk iop(6/33=2,6/42=6)"
    echo ""
    echo "ESP charges calculation"
    echo ""
    echo "${charge} 1"
    cat "${new}_tmp"
    echo ""
    echo ""
    echo ""
  } > "${new}.gjf"

  # Clean up temporary file
  rm "${new}_tmp"

  ## Run Gaussian
  gaussinput=$new
  g16 $gaussinput

  ############################
  ## Part2: Calculate RESP  ##
  ############################

  rm esp-tmp-${new}.chk
  output=$new
  mkdir $output
  cp ${new}.log $output/lig.log

  # produce many files including .ac file
  cd $output/
  antechamber -i lig.log -fi gout -o lig.mol2 -fo mol2 -pf y -c resp
  parmchk2 -i lig.mol2 -f mol2 -o lig.frcmod
  tleap -f ../leap.in
  python2.7 ../acpype.py -p lig.prmtop -x lig.inpcrd -d
  cp MOL_GMX.top MOL.itp

  # delete invalid lines
  line=(`wc -l MOL.itp`)
  var=(`echo $(($line-5))`)
  sed -i "$var,/$line/d" MOL.itp
  sed -i '2,6d' MOL.itp

  # add position restraint at the bottom of the file
  echo '; Include Position restraint file' >> MOL.itp
  echo '#ifdef POSRES' >> MOL.itp
  echo '#include "posre_MOL.itp"' >> MOL.itp
  echo '#endif' >> MOL.itp

  mv ../${new}.* .
  cd ..
done

echo "RESP charges were calculated."
