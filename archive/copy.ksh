#!/bin/ksh

EXP=FreeRunLow4
PSLOT=$EXP-2018091100-2018091800
CDUMP="gdas"
datapath=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/$PSLOT/$CDUMP.20180923/00
cd /gpfs/hps2/stmp/Donald.E.Lippi/archive/
mkdir -p $PSLOT
cd $PSLOT


fhr=000
fmax=936
finc=24
typeset -Z3 fhr

concurrent_jobs=0
while [[ $fhr -le $fmax ]]; do
  echo "$fhr"

  atmnc4=$CDUMP.t00z.atmf$fhr.nc4
  masternc4=$CDUMP.t00z.master.grb2f$fhr.nc4
  atmnems=$CDUMP.t00z.atmf$fhr.nemsio
  sfcnems=$CDUMP.t00z.sfcf$fhr.nemsio

  atmnc4=$datapath/$atmnc4
  masternc4=$datapath/$masternc4
  atmnems=$datapath/$atmnems
  sfcnems=$datapath/$sfcnems

  cp -p $atmnc4 . &    ; job1=$!
  cp -p $masternc4 . & ; job2=$!
  cp -p $atmnems . &   ; job3=$!
  cp -p $sfcnems . &   ; job4=$!

  (( concurrent_jobs=$concurrent_jobs+4 ))
  if [[ $concurrent_jobs -ge 12 ]]; then; echo "wait..."; wait $job1 $job2 $job3 $jobs4; concurrent_jobs=0; fi
  if [[ $fhr -eq $fmax ]]; then; wait; fi

  (( fhr=$fhr+$finc ))

done

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/archive

cat << EOF >> arch.$EXP.ksh
#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J gfsarch_$EXP
#BSUB -W 06:00                    # wall-clock time (hrs:mins)
#BSUB -n 1                        # number of tasks in job
#BSUB -R "rusage[mem=8192]"       # number of cores
#BSUB -q "dev_transfer"           # queue
#BSUB -o gfsarch_$EXP.log      # output file name in which %J is replaced by the job ID

datapath="/gpfs/hps2/stmp/Donald.E.Lippi/archive/$PSLOT"
ATARDIR0="/NCEPDEV/emc-meso/5year/Donald.E.Lippi/rw_FV3GFS"
cd \$datapath/..
htar -cvf \$ATARDIR0/$PSLOT.tar $PSLOT
EOF
