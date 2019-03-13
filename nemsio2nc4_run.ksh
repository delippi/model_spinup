#!/bin/ksh
# This program is a wrapper shell code to convert fv3gfs model output
# from nemsio to netcdf4 in order to run the model spin up code.

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir -p figs

#exps="FreeRunLow1 FreeRunLow2 NATURE NODA"
exps="FreeRunLow1 FreeRunLow2"
#exps="FreeRunLow1"

fhr=0
fmax=936 #39 days
finc=24
nemsio=".true."
grb2=".false."
RES=384
#RES=768

if [[ $RES -eq 384 ]]; then; concurrent_jobs=3; fi
if [[ $RES -eq 768 ]]; then; concurrent_jobs=3 ; fi


for exp in $exps; do

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir convert2nc4
cd convert2nc4
cat /dev/null > nemsio2nc4.$exp.log 
cp ../templates/convert2nc4.template.ksh convert2nc4.$exp.ksh
sed -i                         "s/@exp@/$exp/g" convert2nc4.$exp.ksh
sed -i                         "s/@fhr@/$fhr/g" convert2nc4.$exp.ksh
sed -i                       "s/@fmax@/$fmax/g" convert2nc4.$exp.ksh
sed -i                       "s/@finc@/$finc/g" convert2nc4.$exp.ksh
sed -i                   "s/@nemsio@/$nemsio/g" convert2nc4.$exp.ksh
sed -i                       "s/@grb2@/$grb2/g" convert2nc4.$exp.ksh
sed -i "s/@concurrent_jobs@/$concurrent_jobs/g" convert2nc4.$exp.ksh


bsub < convert2nc4.$exp.ksh
#ksh convert2nc4.$exp.ksh

done
