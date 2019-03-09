#!/bin/ksh

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir -p figs

datapath1='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NATURE-2018091100-2018091800/gfs.20180911/00/'
datapath2='/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NODA-2018091100-2018091800/gfs.20180911/06/'


SDATE=2018091100
fields="ugrdmidlayer tmpmidlayer pressfc spfhmidlayer"
#fields="ugrdmidlayer"
#fields="pressfc"
#fields="pressfc ugrdmidlayer"

fhr=0
fmax=594
finc=24

for field in $fields; do

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup
mkdir $field
cd $field
cat /dev/null > model_spinup_$field.log
cp ../templates/model_spinup_template.py model_spinup_$field.py
sed -i       "s/@varname@/$field/g" model_spinup_$field.py
sed -i         "s/@SDATE@/$SDATE/g" model_spinup_$field.py
sed -i "s#@datapath1@#$datapath1#g" model_spinup_$field.py
sed -i "s#@datapath2@#$datapath2#g" model_spinup_$field.py
sed -i             "s/@fhr@/$fhr/g" model_spinup_$field.py
sed -i           "s/@fmax@/$fmax/g" model_spinup_$field.py
sed -i           "s/@finc@/$finc/g" model_spinup_$field.py


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
