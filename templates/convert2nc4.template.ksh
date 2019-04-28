#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J nemsio2nc4.@exp@
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                       # number of tasks in job
#BSUB -R "rusage[mem=3072]"       # number of cores
#BSUB -q "dev"                    # queue
#BSUB -o nemsio2nc4.@exp@.log               # output file name in which %J is replaced by the job ID

cdump=@cdump@
path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/@exp@-2018091100-2018091800/$cdump.20180911/00
#path=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/@exp@-2018091100-2018091800/$cdump.20180923/00
cd $path

fhr=@fhr@
fmax=@fmax@
finc=@finc@
nemsio="@nemsio@"
grb2="@grb2@"
concurrent_jobs=@concurrent_jobs@
typeset -Z3 fhr

#        500mb zonal wind, meridional wind, temperature, and specific humidity, and sfc pressure.
variable_list="UGRD_P0_L100_GGA0,VGRD_P0_L100_GGA0,TMP_P0_L100_GGA0,SPFH_P0_L100_GGA0,PRES_P0_L1_GGA0"

count=0
while [[ $fhr -le $fmax ]]; do
   echo "$fhr"
   if [[ $nemsio == ".true." ]]; then; nemsio2nc4.py --nemsio $cdump.t00z.atmf$fhr.nemsio &                         ; for_job=$!; fi
   if [[ $grb2   == ".true." ]]; then; ncl_convert2nc $cdump.t00z.master.grb2f$fhr -e grb -v $variable_list -nc4c & ; for_job=$!; fi
   (( count=$count+1 ))
   if [[ $count -eq $concurrent_jobs ]]; then echo "waiting..."; wait $for_job; count=0; fi
   (( fhr=fhr+$finc ))
done
