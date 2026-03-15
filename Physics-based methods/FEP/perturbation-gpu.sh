#!/bin/bash

#SBATCH --job-name LigProt
#SBATCH --time 2-00:00:00
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 8
#SBATCH --mem-per-cpu=1G
#SBATCH -p gpu
#SBATCH --gres gpu:A100:1

# Set some environment variables 
module load gromacs/2022.5_gcc_9.5.0_openmpi_4.1.5_cuda
LAMBDA=$1
MDP=$2/MDPfiles
echo $MDP
FREE_ENERGY=`pwd`

    # A new directory will be created for each value of lambda and
    # at each step in the workflow for maximum organization.

    mkdir Lambda_$LAMBDA
    cd Lambda_$LAMBDA

    ##############################
    # ENERGY MINIMIZATION STEEP  #
    ##############################
    echo "Starting minimization for lambda = $LAMBDA..."

    mkdir EM
    cd EM

    # Iterative calls to grompp and mdrun to run the simulations

    gmx_mpi grompp -f $MDP/em_steep_$LAMBDA.mdp -c $FREE_ENERGY/ions.gro -p $FREE_ENERGY/topol.top -o min$LAMBDA.tpr -maxwarn 1 

    gmx_mpi mdrun -deffnm min$LAMBDA

    rm step*.pdb

    #####################
    # NVT EQUILIBRATION #
    #####################
    echo "Starting constant volume equilibration..."

    cd ../
    mkdir NVT
    cd NVT

    gmx_mpi grompp -f $MDP/nvt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/topol.top -o nvt$LAMBDA.tpr -maxwarn 1 

    gmx_mpi mdrun -v -deffnm nvt${LAMBDA} -cpi -ntomp 8
 
    echo "Constant volume equilibration complete."

    #####################
    # NPT EQUILIBRATION #
    #####################
    echo "Starting constant pressure equilibration..."

    cd ../
    mkdir NPT
    cd NPT

    gmx_mpi grompp -f $MDP/npt_$LAMBDA.mdp -c ../NVT/nvt$LAMBDA.gro -p $FREE_ENERGY/topol.top -t ../NVT/nvt$LAMBDA.cpt -o npt$LAMBDA.tpr -maxwarn 1 

    gmx_mpi mdrun -v -deffnm npt${LAMBDA} -cpi -ntomp 8

    echo "Constant pressure equilibration complete."

    #################
    # PRODUCTION MD #
    #################
    echo "Starting production MD simulation..."

    cd ../
    mkdir Production_MD
    cd Production_MD

    gmx_mpi grompp -f $MDP/md_5ns_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/topol.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 1 

    gmx_mpi mdrun -v -deffnm md${LAMBDA} -cpi -ntomp 8

