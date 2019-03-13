#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J nemsio2nc4.@exp@
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                       # number of tasks in job
#BSUB -R "rusage[mem=3072]"       # number of cores
#BSUB -q "dev"                    # queue
#BSUB -o nemsio2nc4.@exp@.log               # output file name in which %J is replaced by the job ID

path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/@exp@-2018091100-2018091800/gfs.20180911/00
cd $path

fhr=@fhr@
fmax=@fmax@
finc=@finc@
nemsio="@nemsio@"
grb2="@grb2@"
concurrent_jobs=@concurrent_jobs@
typeset -Z3 fhr

count=0
while [[ $fhr -le $fmax ]]; do
   echo "$fhr"
   if [[ $nemsio == ".true." ]]; then; nemsio2nc4.py --nemsio gfs.t00z.atmf$fhr.nemsio &       ; for_job=$!; fi
   if [[ $grb2   == ".true." ]]; then; ncl_convert2nc gfs.t00z.master.grb2f$fhr -e grb -nc4c & ; for_job=$!; fi
   (( count=$count+1 ))
   if [[ $count -eq $concurrent_jobs ]]; then echo "waiting..."; wait $for_job; count=0; fi
   (( fhr=fhr+$finc ))
done
