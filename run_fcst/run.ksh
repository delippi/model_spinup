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

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst
   - change to 00z run in fcst.sh
ksh run.ksh

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
mkdir -p ../06
cd ../06
cp -r ../00/RESTART .
cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst
   - change to 06z run in fcst.sh
ksh run.ksh

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06
mkdir -p ../12
cd ../12
cp -r ../06/RESTART .
cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst
   - change to 12z run in fcst.sh
ksh run.ksh

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911
dbrowse 06/gdas.t06z.atmf009.nemsio 12/gdas.t12z.atmf003.nemsio &

                       00z
a5a6cc0351afd79e0857ff809568f6bc1f39f2b3  gdas.t00z.atmf000.nemsio
0fcea7ab3d73ee0b97e2196080b639b070fe7cad  gdas.t00z.atmf003.nemsio
642129df1f7d217775a98ee4cf701041a665b395  gdas.t00z.atmf006.nemsio
703ea303111221348db42f125612cef9e6b77773  gdas.t00z.atmf009.nemsio
c6ec9cd89bae6d89d7928651af5c62f078c6fbd3  gdas.t00z.sfcf000.nemsio
82f49ca75a9d65002661fd5a210c85ed1fb225d1  gdas.t00z.sfcf003.nemsio
c55446d05ae609e60323bd323085cd54c1619b9a  gdas.t00z.sfcf006.nemsio
6e7b745d987c401e795d8f07cd3712b0406ec403  gdas.t00z.sfcf009.nemsio

                      06z
e8420cc0437991940c53d6d9e2d91c34389c518c  gdas.t06z.atmf000.nemsio     
49a461bd7c2207406a1736c1fd46c3ad3156bed7  gdas.t06z.atmf003.nemsio
d3946165a6b8e604d91a6bd6735eadb3dc983c53  gdas.t06z.atmf006.nemsio
0f1261003dd8afb5283a92195dfd45b1ef94c012  gdas.t06z.atmf009.nemsio
575ec207a5cea8a5be7e581636d13edf3f659216  gdas.t06z.sfcf000.nemsio
ed9a1c79b2cc3534b145df69fb09e148790e57a0  gdas.t06z.sfcf003.nemsio
b2687f8767190c108514341396e48cfd912ac1d3  gdas.t06z.sfcf006.nemsio
1ae7e8fb6b9969ee35915e67f55b330f757a4ac0  gdas.t06z.sfcf009.nemsio

                      12z
ffa7fd7787150ad470fadc04e586249ffb85cd94  gdas.t12z.atmf000.nemsio
2f991d8bc6f691ab224c1304b3ab232bea4f9d64  gdas.t12z.atmf003.nemsio
f6a8f825bb74aa09522f5cd49c0a0421c89f3bf4  gdas.t12z.atmf006.nemsio
1da8ad87a12dd6591beae1b8249933ad914fb106  gdas.t12z.atmf009.nemsio
71ef04e5884cb2b38dd17483d2d36006ea6d4433  gdas.t12z.sfcf000.nemsio
4ab58ac4de68b781079389565b47693318d62b7a  gdas.t12z.sfcf003.nemsio
2c8e0e097f6dcd1f57278efe28f5e36aec5bf297  gdas.t12z.sfcf006.nemsio
09f18b030f1101fd0c788076ffadb810de3f78a6  gdas.t12z.sfcf009.nemsio




cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
nemsio2nc4.py --nemsio gdas.t00z.atmf009.nemsio
nemsio2nc4.py --nemsio gdas.t00z.sfcf009.nemsio

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06
nemsio2nc4.py --nemsio gdas.t06z.atmf003.nemsio
nemsio2nc4.py --nemsio gdas.t06z.sfcf003.nemsio

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06
nemsio2nc4.py --nemsio gdas.t06z.atmf009.nemsio
nemsio2nc4.py --nemsio gdas.t06z.sfcf009.nemsio

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/12
nemsio2nc4.py --nemsio gdas.t12z.atmf003.nemsio
nemsio2nc4.py --nemsio gdas.t12z.sfcf003.nemsio

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst
python compare_00zf09_06zf03.py
"""



#bsub < run_fcst.ksh
bsub < fcst.sh
