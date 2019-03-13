#!/bin/ksh

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir -p figs

#Choose the experiment path
#datapath1='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NATURE-2018091100-2018091800/gfs.20180911/00/'
#datapath2='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NODA-2018091100-2018091800/gfs.20180911/06/'
datapath1='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow1-2018091100-2018091800/gfs.20180911/00/'
datapath2='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow2-2018091100-2018091800/gfs.20180911/00/'

#Start date for the experiment
SDATE=2018091100

#Choose model fields if a nemsio type, the code will know to read from nemsio output and vice versa for grb2.
#You have to use the nemsio2nc4_run.ksh shell code wrapper first to convert nemsio/grb2 into nc4.
fields="ugrdmidlayer tmpmidlayer pressfc spfhmidlayer"
#fields="pressfc"
#fields="pressfc ugrdmidlayer"
fields="ugrdmidlayer"

fields="UGRD_P0_L100_GGA0 TMP_P0_L100_GGA0 SPFH_P0_L100_GGA0 PRES_P0_L101_GGA0"
fields="UGRD_P0_L100_GGA0 TMP_P0_L100_GGA0 SPFH_P0_L100_GGA0"
fields="UGRD_P0_L100_GGA0"

#Choose start, end, and increment times
fhr=0
fmax=936
finc=24

#Choose model resolution (384=26km; 768=13km)
RES=384
#RES=768

#Pick type of calculation
RootMeanSquareDiff="True"
Energy="False"

#Execute shell code based on selected parameters
for field in $fields; do

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir $field
cd $field
cat /dev/null > model_spinup_$field.log
cp ../templates/model_spinup_template.py model_spinup_$field.py
sed -i                         "s/@varname@/$field/g" model_spinup_$field.py
sed -i                           "s/@SDATE@/$SDATE/g" model_spinup_$field.py
sed -i                   "s#@datapath1@#$datapath1#g" model_spinup_$field.py
sed -i                   "s#@datapath2@#$datapath2#g" model_spinup_$field.py
sed -i                               "s/@fhr@/$fhr/g" model_spinup_$field.py
sed -i                             "s/@fmax@/$fmax/g" model_spinup_$field.py
sed -i                             "s/@finc@/$finc/g" model_spinup_$field.py
sed -i                               "s/@RES@/$RES/g" model_spinup_$field.py
sed -i "s/@RootMeanSquareDiff@/$RootMeanSquareDiff/g" model_spinup_$field.py
sed -i                         "s/@Energy@/$Energy/g" model_spinup_$field.py


cat << EOF > model_spinup_$field.ksh
#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J model_spinup_$field
#BSUB -W 01:25                 # wall-clock time (hrs:mins)
#BSUB -n 1                     # number of tasks in job
#BSUB -R "rusage[mem=3072]"    # number of cores
#BSUB -q "dev"                 # queue
#BSUB -o model_spinup_$field.log      # output file name in which %J is replaced by the job ID

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/$field
python ./model_spinup_$field.py

EOF

bsub < model_spinup_$field.ksh
#ksh model_spinup_$field.ksh

done
