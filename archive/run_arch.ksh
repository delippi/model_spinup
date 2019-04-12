#!/bin/ksh
#set -x
export ndate=/gpfs/hps2/u/Donald.E.Lippi/bin/ndate

SDATE=2018092300
#EDATE=2018091200
EDATE=2018092300
EXP=FreeRunLow4

#The next two lines are meant to break the task of copying files to a temp dir
#and then archiving them since there is so much data and the wall time will
#likely be >6hrs
copy_files="YES"
archive_files="NO"

CDATE=$SDATE
offset=0

cd /gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/archive

while [ $CDATE -le $EDATE ]; do
      cp -p templates/archive_template.ksh archive_$CDATE.ksh
      sed -i                 "s/@CDATE@/$CDATE/g" archive_$CDATE.ksh
      sed -i                     "s/@EXP@/$EXP/g" archive_$CDATE.ksh
      sed -i               "s/@OFFSET@/$offset/g" archive_$CDATE.ksh
      sed -i       "s/@copy_files@/$copy_files/g" archive_$CDATE.ksh
      sed -i "s/@archive_files@/$archive_files/g" archive_$CDATE.ksh
      #bsub < archive_$CDATE.ksh 
      ksh archive_$CDATE.ksh 
      CDATE=`${ndate} +24 $CDATE` #increment by 24 hours
      (( offset=offset+1 )) #increment by 1 day
done


