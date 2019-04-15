#!/bin/ksh -x
#BSUB -P FV3GFS-T2O
#BSUB -J gfs_fcst
#BSUB -W 00:08                 # wall-clock time (hrs:mins)
#BSUB -M 256
#BSUB -q "dev"                 # queue
#BSUB -o gfs_fcst.log           # output file name in which %J is replaced by the job ID
#BSUB -R "1*{select[craylinux && !vnode]} + 1920*{select[craylinux && vnode]span[ptile=24]}"
#BSUB -extsched 'CRAYLINUX[]'

#                  00                                                                  06
#a5a6cc0351afd79e0857ff809568f6bc1f39f2b3  gdas.t00z.atmf000.nemsio
#81b7c6782e498f69908dd895680303ae8913923e  gdas.t00z.atmf003.nemsio
#8cc91592e278fe50848dd4e0b17464785524633d  gdas.t00z.atmf006.nemsio
#a8674dac71182905e3a5cf9f6245e7f04595480a  gdas.t00z.atmf009.nemsio
#c6ec9cd89bae6d89d7928651af5c62f078c6fbd3  gdas.t00z.sfcf000.nemsio
#dfdb32eaba24c986e9d4f11444969a2c3630e9c0  gdas.t00z.sfcf003.nemsio
#11a82bf70b643d4c5d2c648863b5aa6ea25bd5db  gdas.t00z.sfcf006.nemsio
#408770c1a2d08ab97ef73fc8c6d7eea69f15aedc  gdas.t00z.sfcf009.nemsio



export PDY="20180911"
export cyc="12"
export CDUMP="gdas"
export CDATE="${PDY}${cyc}"


#-- Experiment parameters such as name, starting, ending dates -->
export PSLOT="FreeRunLow5-2018091100-2018091800"
export SDATE="201809110000"
export EDATE="201809240000"

#-- Starting and ending dates for GFS cycle -->
export SDATE_GFS="201809120000"
export EDATE_GFS="201809240000"
export INTERVAL_GFS="24:00:00"

#-- Run Envrionment -->
export RUN_ENVIR="emc"

#-- Experiment and Rotation directory -->
export EXPDIR="/gpfs/hps3/emc/meso/noscrub/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800"
export ROTDIR="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800"

#-- Directories for driving the workflow -->
export HOMEgfs="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/global-workflow-20190306"
export JOBS_DIR="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/global-workflow-20190306/jobs/rocoto"
export DMPDIR="/gpfs/tp1/emc/globaldump"

#-- Machine related entities -->
export ACCOUNT="FV3GFS-T2O"
export QUEUE="dev"
export QUEUE_ARCH="dev_transfer"
export SCHEDULER="lsfcray"

#-- Toggle HPSS archiving -->
export ARCHIVE_TO_HPSS="YES"


###############################################################
# Source FV3GFS workflow modules
. load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Execute the JJOB
./JGLOBAL_FORECAST
status=$?
exit $status
