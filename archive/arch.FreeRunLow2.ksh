#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J gfsarch_FreeRunLow2
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                        # number of tasks in job
#BSUB -R "rusage[mem=8192]"       # number of cores
#BSUB -q "dev_transfer"           # queue
#BSUB -o gfsarch_FreeRunLow2.log      # output file name in which %J is replaced by the job ID

datapath="/gpfs/hps2/stmp/Donald.E.Lippi/archive/FreeRunLow2-2018091100-2018091800"
ATARDIR0="/NCEPDEV/emc-meso/5year/Donald.E.Lippi/rw_FV3GFS"
cd $datapath/..
htar -cvf $ATARDIR0/FreeRunLow2-2018091100-2018091800.tar FreeRunLow2-2018091100-2018091800
