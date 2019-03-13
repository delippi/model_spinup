#!/bin/ksh

export ndate=/gpfs/hps2/u/Donald.E.Lippi/bin/ndate
cd /scratch4/NCEPDEV/stmp3/Donald.E.Lippi/fv3gfs_dl2rw

input_nemsio="NO" #probably doesn't work
input_grib2="YES"

if [[ $input_grib2  == "YES" ]]; then; suffix="grib2nc";   fi
if [[ $input_nemsio == "YES" ]]; then; suffix="nemsio2nc"; fi

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/
mkdir -p plots/figs
cd sfc_plots
EXP="FreeRunLow"
EXP1="FreeRunLow1"
EXP2="FreeRunLow2"
cyc="00"
pdy=20180911
date_exp_start=2018091100

group=4

#sets of 10
if   [[ $group -eq 1 ]]; then
   FHSTART=0
   FHEND=216
elif [[ $group -eq 2 ]]; then
   FHSTART=240
   FHEND=456
elif [[ $group -eq 3 ]]; then
   FHSTART=480
   FHEND=696
elif [[ $group -eq 4 ]]; then 
   FHSTART=720
   FHEND=936
fi

FHINC=24

typeset -Z2 cyc

#pyfv3graphics="/scratch4/NCEPDEV/fv3-cam/save/Donald.E.Lippi/py-fv3graphics"

FH=$FHSTART
#concurrent_jobs=0
while [[ $FH -le $FHEND ]]; do

   rm -f fv3gfs_osse_plot.log

   echo "cp -p ../templates/make_plots_template.ksh make_plots_${suffix}.ksh"
   cp -p ../templates/make_plots_template.ksh make_plots_${suffix}.ksh
   sed -i                     "s/@EXP@/${EXP}/g" make_plots_${suffix}.ksh
   sed -i                   "s/@EXP1@/${EXP1}/g" make_plots_${suffix}.ksh
   sed -i                   "s/@EXP2@/${EXP2}/g" make_plots_${suffix}.ksh
   sed -i                   "s/@cycs@/${cycs}/g" make_plots_${suffix}.ksh
   sed -i                  "s/@make_figs@/YES/g" make_plots_${suffix}.ksh
   sed -i "s/@date_exp_start@/$date_exp_start/g" make_plots_${suffix}.ksh
   sed -i                    "s/@FHSTART@/$FH/g" make_plots_${suffix}.ksh
   sed -i                      "s/@FHEND@/$FH/g" make_plots_${suffix}.ksh
   sed -i     "s/@input_nemsio@/$input_nemsio/g" make_plots_${suffix}.ksh
   sed -i       "s/@input_grib2@/$input_grib2/g" make_plots_${suffix}.ksh

   bsub < make_plots_${suffix}.ksh
   #ksh  make_plots_${suffix}.ksh
   
   #(( concurrent_jobs=$concurrent_jobs+1 ))
   #if [[ $concurrent_jobs -eq 10 ]]; then; wait $job; concurrent_jobs=0; fi #wait and reset job count

   FH=$(( $FH + $FHINC))
done



