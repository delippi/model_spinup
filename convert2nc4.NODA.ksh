#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J nemsio2nc4.NODA
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                       # number of tasks in job
#BSUB -R "rusage[mem=3072]"       # number of cores
#BSUB -q "dev"                    # queue
#BSUB -o nemsio2nc4.NODA.log               # output file name in which %J is replaced by the job ID

path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NODA-2018091100-2018091800/gfs.20180911/06
cd $path

fhr=144
typeset -Z3 fhr

while [[ $fhr -le 240 ]]; do
   echo "$fhr"
   if [[ ! -e gfs.t06z.atmf$fhr.nemsio ]]; then; echo "wait 60s \n"; sleep 60; fi
   nemsio2nc4.py --nemsio gfs.t06z.atmf$fhr.nemsio & ; for_job=$!
   (( mod=$fhr%9 ))
   if [[ $mod -eq 0 ]]; then; echo "waiting...";  wait $for_job; fi
   (( fhr=fhr+3 ))
done
