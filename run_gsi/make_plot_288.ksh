#!/bin/ksh

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_gsi


file2=gfs.t00z.master.grb2f288.nc4
file3=gdas.t18z.master.grb2f006.nc4

experiment_name="Run2"
filename=$file2
datadir="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_gsi"
pdy=2018091100
cyc=00
valpdy=20180923
valcyc=00
valtime=${valpdy}${valcyc}
fhr=288

input1="$experiment_name $filename $datadir $pdy $cyc $valpdy $valcyc $valtime $fhr"



experiment_name="Run3"
filename=$file3
datadir="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_gsi"
pdy=2018091100
cyc=00
valpdy=20180923
valcyc=00
valtime=${valpdy}${valcyc}
fhr=288


input2="$experiment_name $filename $datadir $pdy $cyc $valpdy $valcyc $valtime $fhr"

input="2 $input1 $input2"


python /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/fv3_grib2nc_multi.py $input
