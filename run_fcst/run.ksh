#!/bin/ksh

cp gfs_fcst.log gfs_fcst.log.1
cat /dev/null > gfs_fcst.log

#Use this script to run your free forecast. But first you must have Restart files located for example,
#/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06
#So to do this,
# 1. Set up an experiment. Run the first cycle with the workflow.
# 2. Manually copy the restart files to the 06 dir
# 3. Run this script!

"""
mkdir -p /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FV3ICS/FreeRunLow5-2018091100-2018091800/
cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FV3ICS/FreeRunLow5-2018091100-2018091800/
htar -xvf /NCEPDEV/emc-meso/5year/Donald.E.Lippi/rw_FV3GFS/FreeRunLow2-2018091100-2018091800.ics.tar

mkdir -p /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
mv /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FV3ICS/FreeRunLow5-2018091100-2018091800/INPUT .

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/PhD-globalRadarOSSE
ksh run_FreeRunLow5.ksh

cd /gpfs/hps3/emc/meso/noscrub/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800
vi config.base
   - HYBVAR=NO
ksh run.ksh


                       00z                                       
a5a6cc0351afd79e0857ff809568f6bc1f39f2b3  gdas.t00z.atmf000.nemsio     
81b7c6782e498f69908dd895680303ae8913923e  gdas.t00z.atmf003.nemsio     
8cc91592e278fe50848dd4e0b17464785524633d  gdas.t00z.atmf006.nemsio     ff05a293773c808e54fee28ca3c14ff87fb8f323  gdas.t06z.atmf000.nemsio
a8674dac71182905e3a5cf9f6245e7f04595480a  gdas.t00z.atmf009.nemsio     d88e08bf956149873214bdb100dcda7421b5bf2d  gdas.t06z.atmf003.nemsio

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
mkdir -p ../06
mv RESTART ../06/.
cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst
ksh run.ksh

"""



#bsub < run_fcst.ksh
bsub < fcst.sh
