#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J gfsarch
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                        # number of tasks in job
#BSUB -R "rusage[mem=8192]"       # number of cores
#BSUB -q "dev_transfer"           # queue
#BSUB -o gfsarch.log      # output file name in which %J is replaced by the job ID

PSLOT="FreeRunLow1-2018091100-2018091800"
datapath="/gpfs/hps2/stmp/Donald.E.Lippi/archive/$PSLOT"
ATARDIR0="/NCEPDEV/emc-meso/5year/Donald.E.Lippi/rw_FV3GFS"

cd $datapath/..

htar -cvf $ATARDIR0/$PSLOT.tar $PSLOT
