#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J fv3gfs_osse_post_@EXP@
#BSUB -W 06:00                      # wall-clock time (hrs:mins)
#BSUB -n 1                          # number of tasks in job
#BSUB -R "rusage[mem=3072]"         # number of cores
#BSUB -q "dev"                      # queue
#BSUB -o fv3gfs_osse_plot_@EXP@.log # output file name in which %J is replaced by the job ID

#set -x
echo "make plot/pull script start"
export ndate=/gpfs/hps2/u/Donald.E.Lippi/bin/ndate
EXP="@EXP@"
EXP1="@EXP1@"
EXP2="@EXP2@"
cycs="@cycs@"
DATES="2018091100-2018091800"
date_exp_start=@date_exp_start@
input_nemsio="@input_nemsio@"
input_grib2="@input_grib2@"
BASE="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/"
typeset -Z2 cyc


#pyfv3graphics="/scratch4/NCEPDEV/fv3-cam/save/Donald.E.Lippi/py-fv3graphics"
FIGS="sfc_figs"

#SETUP COUNTERS
FHSTART=@FHSTART@ #00
FHEND=@FHEND@ #24
FHINC=1
FH=$FHSTART


while [[ $FH -le $FHEND ]]; do

   pdy_exp_start=`echo $date_exp_start | cut -c 1-8`
   cyc_exp_start=`echo $date_exp_start | cut -c 9-10`
   yyyy_exp_start=`echo $date_exp_start | cut -c 1-4`
   mm_exp_start=`echo $date_exp_start | cut -c 5-6`

   date_exp_valid=`$ndate +$FH $date_exp_start`
   pdy_exp_valid=`echo $date_exp_valid | cut -c 1-8`
   cyc_exp_valid=`echo $date_exp_valid | cut -c 9-10`
   yyyy_exp_valid=`echo $date_exp_valid | cut -c 1-4`
   mm_exp_valid=`echo $date_exp_valid | cut -c 5-6`


   typeset -Z3 FH

   #PROCESSING GRIB2 FILES
   if [[ $input_grib2 == "YES" ]]; then
      ATMDIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.master.grb2" #master grib2 atmos directory
      ATMFILE="gfs.t${cyc_exp_start}z.master.grb2f${FH}"           #master grib2 atmos file

      ATMNC4DIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.atm.nc4" #netcdf4 atmos directory
      NC4FILE="gfs.t${cyc_exp_start}z.master.grb2f${FH}.nc4"      #netcdf4 atmos file

      #convert2nc4="ncl_convert2nc ${ATMFILE} -e grb -nc4c"
      plot="python ${BASE}/fv3_grib2nc_multi.py"

   #PROCESSING NEMSIO FILES
   elif [[ $input_nemsio == "YES" ]]; then
      ATMDIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.atm.nemsio" #nemsio atmos directory
      ATMFILE="gfs.t${cyc_exp_start}z.atmf${FH}.nemsio"           #nemsio atmos file

      ATMNC4DIR="gfs.t${cyc_exp_start}z.${pdy_exp_start}.atm.nc4" #netcdf4 atmos directory
      NC4FILE="gfs.t${cyc_exp_start}z.atmf${FH}.nc4"              #netcdf4 atmos file

      #convert2nc4="python /home/Rahul.Mahajan/bin/nemsio2nc4.py --nemsio ${ATMFILE} "
      #plot="python ${pyfv3graphics}/fv3_${EXP}_nemsio2nc.py"
      exit
   fi

   #CREATE THE WORKSPACE
   WORK_MAIN="${BASE}/sfc_plots"
   mkdir -p $WORK_MAIN
   WORK1=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP1}-${DATES}/gfs.20180911/00
   WORK2=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/${date_exp_start}/${EXP2}-${DATES}/gfs.20180911/00

   echo $FH

   atmdir=$ATMDIR
   atmfile=$ATMFILE
   atmnc4dir=$ATMNC4DIR
   nc4file=$NC4FILE

   cd $work

   #CREATE THE PLOT NOW IF NOT ALREADY DONE
   FIG="gfs.t${cyc_exp_start}z.${date_exp_start}_v${date_exp_valid}_atmf${FH}.png"
   cd $WORK_MAIN

   datadir1="${WORK1}"
   datadir2="${WORK2}"
   filename=$NC4FILE
   input=""
   common_in="$pdy_exp_start $cyc_exp_start $pdy_exp_valid $cyc_exp_valid $date_exp_valid $FH"
   input="$input $EXP1 $filename $datadir1 $common_in"
   input="$input $EXP2 $filename $datadir2 $common_in" 
   input="2 $input" #put count first
   echo $input
   $plot $input

   mv $datadir/${FIG} ./${FIG}
   cd $WORK_MAIN
   (( FH=$FH+$FHINC ))
done

