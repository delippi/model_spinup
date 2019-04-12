#!/bin/ksh -x
#BSUB -P FV3GFS-T2O
#BSUB -J gfs_fcst
#BSUB -W 00:08                 # wall-clock time (hrs:mins)
#BSUB -M 256
#BSUB -q "dev"                 # queue
#BSUB -o gfs_fcst.log           # output file name in which %J is replaced by the job ID
#BSUB -R "1*{select[craylinux && !vnode]} + 1920*{select[craylinux && vnode]span[ptile=24]}"
#BSUB -extsched 'CRAYLINUX[]'

#00
#913c22ac2408e333ce26e5df9f2385e2510a63a2  gdas.t00z.atmf000.nemsio v00
#007e7b97a2ece2b708aead001ec925a97d8274cf  gdas.t00z.atmf003.nemsio v03
#7cc51fa5330be461592a273eebef69cf1afd0b40  gdas.t00z.atmf006.nemsio v06
#5afb69d530b3ce9873e9b0f1ea7ee1170f5d8c7d  gdas.t00z.atmf009.nemsio v09
##
#46d952068f2f5840527c07bf341bbcd0946b0e4a  atmf000.tile1.nc
#3d51753fc1cadc88a1d415a4ac107453c7ee6147  atmf003.tile1.nc
#00b34c2629ef42a9659af491d897e7812aa6ca13  atmf006.tile1.nc
#22de5b93f493e8cc68c9b8c8b4df5128a13cbfea  atmf009.tile1.nc

#06
#bb34d02fec9dd6766b45b5a13e8365f66a6e0ff9  gdas.t06z.atmf000.nemsio v06
#4f07827aebd4756d3af52578a3c5d97381df6e56  gdas.t06z.atmf003.nemsio v09
#3da621875f72daad97d8db261743d504ea01822b  gdas.t06z.atmf006.nemsio v12
#ef6a0223ca2b41c5d80c2c620188ed53d8537bfa  gdas.t06z.atmf009.nemsio v15
##################################################

#00
#cfcee7eb25601e4e5a3a3bfec833d33b7ecde919  gdas.t00z.atmf000.nemsio
#211661d1a3e7ea7efc4726eacdb4bc7d897e36e1  gdas.t00z.atmf003.nemsio
#8aebd9b1cdcb9241f196fd99a51457d0720efeb1  gdas.t00z.atmf006.nemsio
#b0b5f7d7b18aa2106c447d0d82ce38f1825fc107  gdas.t00z.sfcf000.nemsio
#cb0e46a83bfb4391b64499d0c16e8ed7d88c4350  gdas.t00z.sfcf003.nemsio
#b0f25536676cb79c37cce37d1a9d20559f1537b5  gdas.t00z.sfcf006.nemsio
##
#06




export PDY="20180911"
export cyc="06"
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
