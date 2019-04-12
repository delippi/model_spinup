#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J fv3gfs_osse_post_FreeRunLow
#BSUB -W 06:00                      # wall-clock time (hrs:mins)
#BSUB -n 1                          # number of tasks in job
#BSUB -R "rusage[mem=3072]"         # number of cores
#BSUB -q "dev"                      # queue
#BSUB -o fv3gfs_osse_plot_FreeRunLow.log # output file name in which %J is replaced by the job ID

#set -x
echo "make plot/pull script start"
export ndate=/gpfs/hps2/u/Donald.E.Lippi/bin/ndate
EXP="FreeRunLow"
EXP1="FreeRunLow1"
EXP2="FreeRunLow2"
EXP3="FreeRunLow4"
EXP4="FreeRunLow5"
cycs=""
DATES="2018091100-2018091800"
date_exp_start=2018091100
input_nemsio="NO"
input_grib2="YES"
BASE="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/"
typeset -Z2 cyc


#pyfv3graphics="/scratch4/NCEPDEV/fv3-cam/save/Donald.E.Lippi/py-fv3graphics"
FIGS="sfc_figs"

#SETUP COUNTERS
FHSTART=288 #00
FHEND=288 #24
FHINC=1
FH=$FHSTART
date_exp_start2=`$ndate +288 $date_exp_start`

while [[ $FH -le $FHEND ]]; do

   (( FH288=$FH+288 ))
   pdy_exp_start=`echo $date_exp_start | cut -c 1-8` ; pdy_exp_start2=`echo $date_exp_start2 | cut -c 1-8`
   cyc_exp_start=`echo $date_exp_start | cut -c 9-10`; cyc_exp_start2=`echo $date_exp_start2 | cut -c 9-10`
   yyyy_exp_start=`echo $date_exp_start | cut -c 1-4`; yyyy_exp_start2=`echo $date_exp_start2 | cut -c 1-4`
   mm_exp_start=`echo $date_exp_start | cut -c 5-6`  ; mm_exp_start2=`echo $date_exp_start2 | cut -c 5-6`

   date_exp_valid=`$ndate +$FH288 $date_exp_start`   ; date_exp_valid2=`$ndate +$FH $date_exp_start2`
   pdy_exp_valid=`echo $date_exp_valid | cut -c 1-8` ; pdy_exp_valid2=`echo $date_exp_valid2 | cut -c 1-8`
   cyc_exp_valid=`echo $date_exp_valid | cut -c 9-10`; cyc_exp_valid2=`echo $date_exp_valid2 | cut -c 9-10`
   yyyy_exp_valid=`echo $date_exp_valid | cut -c 1-4`; yyyy_exp_valid2=`echo $date_exp_valid2 | cut -c 1-4`
   mm_exp_valid=`echo $date_exp_valid | cut -c 5-6`  ; mm_exp_valid2=`echo $date_exp_valid2 | cut -c 5-6`

   typeset -Z3 FH

   #PROCESSING GRIB2 FILES
   if [[ $input_grib2 == "YES" ]]; then
      ATMDIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.master.grb2" #master grib2 atmos directory
      ATMFILE="gfs.t${cyc_exp_start}z.master.grb2f${FH288}"        #master grib2 atmos file
      ATMNC4DIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.atm.nc4"  #netcdf4 atmos directory
      NC4FILE="gfs.t${cyc_exp_start}z.master.grb2f${FH288}.nc4"    #netcdf4 atmos file

      ATMDIR2="gdas.t${cyc_exp_start2}z.${pdy_exp_start2}.master.grb2" #master grib2 atmos directory
      ATMFILE2="gdas.t${cyc_exp_start2}z.master.grb2f${FH}"           #master grib2 atmos file
      ATMNC4DIR2="gdas.t${cyc_exp_start2}z.${pdy_exp_start2}.atm.nc4" #netcdf4 atmos directory
      NC4FILE2="gdas.t${cyc_exp_start2}z.master.grb2f${FH}.nc4"      #netcdf4 atmos file

      #convert2nc4="ncl_convert2nc ${ATMFILE} -e grb -nc4c"
      plot="python ${BASE}/fv3_grib2nc_multi.py"
   fi

   echo "pdy_exp_start   $pdy_exp_start"
   echo "date_exp_valid  $date_exp_valid"
   echo "pdy_exp_start2  $pdy_exp_start2"
   echo "date_exp_valid2 $date_exp_valid2"
  
   echo "ATMDIR    $ATMDIR"
   echo "ATMFILE   $ATMFILE"
   echo "ATMNC4DIR $ATMNC4DIR"
   echo "NC4FILE   $NC4FILE"

   echo "ATMDIR2    $ATMDIR2"
   echo "ATMFILE2   $ATMFILE2"
   echo "ATMNC4DIR2 $ATMNC4DIR2"
   echo "NC4FILE2   $NC4FILE2"


   #CREATE THE WORKSPACE
   WORK_MAIN="${BASE}/plots"
   mkdir -p $WORK_MAIN
   WORK1=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP1}-${DATES}/gfs.20180911/00
   WORK2=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP2}-${DATES}/gfs.20180911/00
   WORK3=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP3}-${DATES}/gdas.20180923/00
   WORK4=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP4}-${DATES}/gdas.20180923/00

   echo $FH

   atmdir=$ATMDIR
   atmfile=$ATMFILE
   atmnc4dir=$ATMNC4DIR
   nc4file=$NC4FILE

   atmdir2=$ATMDIR2
   atmfile2=$ATMFILE2
   atmnc4dir2=$ATMNC4DIR2
   nc4file2=$NC4FILE2

   #CREATE THE PLOT NOW IF NOT ALREADY DONE
   FIG="gfs.t${cyc_exp_start2}z.${date_exp_start2}_v${date_exp_valid2}_atmf${FH}.png"
   cd $WORK_MAIN

   datadir1="${WORK1}"
   datadir2="${WORK2}"
   datadir3="${WORK3}"
   datadir4="${WORK4}"
   filename=$NC4FILE
   filename2=$NC4FILE2
   input=""
   common_in="$pdy_exp_start   $cyc_exp_start  $pdy_exp_valid  $cyc_exp_valid  $date_exp_valid  $FH288"
   common_in2="$pdy_exp_start2 $cyc_exp_start2 $pdy_exp_valid2 $cyc_exp_valid2 $date_exp_valid2 $FH"
   input="$input $EXP1 $filename  $datadir1 $common_in"
   input="$input $EXP2 $filename  $datadir2 $common_in" 
   input="$input $EXP3 $filename2 $datadir3 $common_in2" 
   input="$input $EXP4 $filename2 $datadir4 $common_in2" 
   input="4 $input" #put count first
   echo $input
   $plot $input

   #mv $datadir/${FIG} ./${FIG}
   cd $WORK_MAIN
   (( FH=$FH+$FHINC ))
done

