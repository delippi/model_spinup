#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J nemsio2nc4.FreeRunLow4
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                       # number of tasks in job
#BSUB -R "rusage[mem=3072]"       # number of cores
#BSUB -q "dev"                    # queue
#BSUB -o nemsio2nc4.FreeRunLow4.log               # output file name in which %J is replaced by the job ID

cdump=gdas
path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow4-2018091100-2018091800/$cdump.20180911/00
path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow4-2018091100-2018091800/$cdump.20180923/00
cd $path

fhr=0
fmax=288
finc=24
nemsio=".false."
grb2=".true."
concurrent_jobs=3
typeset -Z3 fhr

count=0
while [[ $fhr -le $fmax ]]; do
   echo "$fhr"
   if [[ $nemsio == ".true." ]]; then; nemsio2nc4.py --nemsio $cdump.t00z.atmf$fhr.nemsio &       ; for_job=$!; fi
   if [[ $grb2   == ".true." ]]; then; ncl_convert2nc $cdump.t00z.master.grb2f$fhr -e grb -nc4c & ; for_job=$!; fi
   (( count=$count+1 ))
   if [[ $count -eq $concurrent_jobs ]]; then echo "waiting..."; wait $for_job; count=0; fi
   (( fhr=fhr+$finc ))
done
