#!/bin/ksh
#BSUB -P FV3GFS-T2O
#BSUB -J gfs_fcst
#BSUB -W 02:30                 # wall-clock time (hrs:mins)
#BSUB -M 1024
#BSUB -q "dev"                 # queue
#BSUB -o gfs_fcst.log           # output file name in which %J is replaced by the job ID
#BSUB -R "1*{select[craylinux && !vnode]} + 1920*{select[craylinux && vnode]span[ptile=24]}"
#BSUB -extsched 'CRAYLINUX[]' 

HOMEgfs=/gpfs/hps3/emc/meso/save/Donald.E.Lippi/global-workflow-20190306
FIXfv3=$HOMEgfs/fix/fix_fv3
FCSTEXEC=$HOMEgfs/exec/global_fv3gfs.x
if_clean=".true."

. $HOMEgfs/ush/load_fv3gfs_modules.sh
configs="base fcst"
config_path=/gpfs/hps3/emc/meso/noscrub/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800
for config in $configs; do
    . $config_path/config.$config
    status=$?
    [[ $status -ne 0 ]] && exit $status
done
. /gpfs/hps3/emc/meso/save/Donald.E.Lippi/global-workflow-20190306/env/WCOSS_C.env "fcst"



echo "number of processors? $LSB_DJOB_NUMPROC"

#####################################################
# case set up (users should change this part)
#####################################################
CDATE=2018091106
CASE=C384
# Cycling and forecast hour specific parameters
CASE=${CASE:-C768}
CDATE=${CDATE:-2017032500}
CDUMP=${CDUMP:-gdas}
FHMIN=${FHMIN:-0}
FHMAX=${FHMAX:-9}
FHOUT=${FHOUT:-3}
FHZER=${FHZER:-6}
FHCYC=${FHCYC:-24}
FHMAX_HF=${FHMAX_HF:-0}
FHOUT_HF=${FHOUT_HF:-1}

NSOUT=${NSOUT:-"-1"}
FDIAG=$FHOUT
if [ $FHMAX_HF -gt 0 -a $FHOUT_HF -gt 0 ]; then FDIAG=$FHOUT_HF; fi

# Directories.
pwd=$(pwd)
NWPROD=${NWPROD:-${NWROOT:-$pwd}}
HOMEgfs=${HOMEgfs:-$NWPROD}
FIX_DIR=${FIX_DIR:-$HOMEgfs/fix}
FIX_AM=${FIX_AM:-$FIX_DIR/fix_am}
FIXfv3=${FIXfv3:-$FIX_DIR/fix_fv3_gmted2010}
DATA=${DATA:-$pwd/fv3tmp$$}    # temporary running directory
ROTDIR=${ROTDIR:-$pwd}         # rotating archive directory
ICSDIR=${ICSDIR:-$pwd}         # cold start initial conditions
DMPDIR=${DMPDIR:-$pwd}         # global dumps for seaice, snow and sst analysis

# Model resolution specific parameters
DELTIM=${DELTIM:-225}
layout_x=${layout_x:-8}
layout_y=${layout_y:-16}
LEVS=${LEVS:-65}

# Utilities
NCP=${NCP:-"/bin/cp -p"}
NLN=${NLN:-"/bin/ln -sf"}
NMV=${NMV:-"/bin/mv"}
SEND=${SEND:-"YES"}   #move final result to rotating directory
ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}
KEEPDATA="YES"

# Model specific stuff
FCSTEXECDIR=${FCSTEXECDIR:-$HOMEgfs/sorc/fv3gfs.fd/NEMS/exe}
FCSTEXEC=${FCSTEXEC:-fv3_gfs.x}
PARM_FV3DIAG=${PARM_FV3DIAG:-$HOMEgfs/parm/parm_fv3diag}

# Model config options
APRUN_FV3=${APRUN_FV3:-${APRUN_FCST:-${APRUN:-""}}}
NTHREADS_FV3=${NTHREADS_FV3:-${NTHREADS_FCST:-${nth_fv3:-1}}}
cores_per_node=${cores_per_node:-${npe_node_max:-24}}
ntiles=${ntiles:-6}
NTASKS_FV3=${NTASKS_FV3:-$npe_fv3}

TYPE=${TYPE:-"nh"}                  # choices:  nh, hydro
MONO=${MONO:-"non-mono"}            # choices:  mono, non-mono

QUILTING=${QUILTING:-".true."}
OUTPUT_GRID=${OUTPUT_GRID:-"gaussian_grid"}
OUTPUT_FILE=${OUTPUT_FILE:-"nemsio"}
WRITE_NEMSIOFLIP=${WRITE_NEMSIOFLIP:-".true."}
WRITE_FSYNCFLAG=${WRITE_FSYNCFLAG:-".true."}

rCDUMP=${rCDUMP:-$CDUMP}

#------------------------------------------------------------------
# setup the runtime environment
if [ $machine = "WCOSS_C" ] ; then
  HUGEPAGES=${HUGEPAGES:-hugepages4M}
  . $MODULESHOME/init/sh 2>/dev/null
  module load iobuf craype-$HUGEPAGES 2>/dev/null
  export MPICH_GNI_COLL_OPT_OFF=${MPICH_GNI_COLL_OPT_OFF:-MPI_Alltoallv}
  export MKL_CBWR=AVX2
  export WRTIOBUF=${WRTIOBUF:-"4M"}
  export NC_BLKSZ=${NC_BLKSZ:-"4M"}
  export IOBUF_PARAMS="*nemsio:verbose:size=${WRTIOBUF},*:verbose:size=${NC_BLKSZ}"
fi

#-------------------------------------------------------
if [ ! -d $ROTDIR ]; then mkdir -p $ROTDIR; fi
mkdata=NO
if [ ! -d $DATA ]; then
   mkdata=YES
   mkdir -p $DATA
fi
mkdir -p $DATA/RESTART $DATA/INPUT
cd $DATA || exit 8

#-------------------------------------------------------
# member directory
if [ $MEMBER -lt 0 ]; then
  prefix=$CDUMP
  rprefix=$rCDUMP
  memchar=""
else
  prefix=enkf.$CDUMP
  rprefix=enkf.$rCDUMP
  memchar=mem$(printf %03i $MEMBER)
fi
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)
memdir=$ROTDIR/${prefix}.$PDY/$cyc/$memchar
if [ ! -d $memdir ]; then mkdir -p $memdir; fi

GDATE=$($NDATE -$assim_freq $CDATE)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)
gmemdir=$ROTDIR/${rprefix}.$gPDY/$gcyc/$memchar

#-------------------------------------------------------
# initial conditions
warm_start=${warm_start:-".false."}
read_increment=${read_increment:-".false."}
restart_interval=${restart_interval:-0}
# Determine if this is a warm start or cold start
if [ -f $gmemdir/RESTART/${PDY}.${cyc}0000.coupler.res ]; then
  export warm_start=".true."
fi

if [ $warm_start = ".true." ]; then

  # Link all (except sfc_data) restart files from $gmemdir
  for file in $gmemdir/RESTART/${PDY}.${cyc}0000.*.nc; do
    file2=$(echo $(basename $file))
    file2=$(echo $file2 | cut -d. -f3-) # remove the date from file
    fsuf=$(echo $file2 | cut -d. -f1)
    if [ $fsuf != "sfc_data" ]; then
       $NLN $file $DATA/INPUT/$file2
    fi
  done



















EXP_NAME=model_spinup_fcst_1
hh=`echo $ANAL_TIME | cut -c9-10`
DATA=/gpfs/hps2/ptmp/$USER/$CDATE/$EXP_NAME
BASEDIR=/gpfs/hps3/emc/meso/save/Donald.E.Lippi/global-workflow-20190306/
#ATMDIR=/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_gsi/
ATMDIR=/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
PREPBUFR=$ATMDIR/prepbufr
ATMG03=$ATMDIR/gdas.t00z.atmf285.nemsio
ATMGES=$ATMDIR/gfs.t00z.atmf288.nemsio
ATMG09=$ATMDIR/gdas.t00z.atmf291.nemsio
SFCG03=$ATMDIR/gdas.t00z.sfcf285.nemsio
SFCGES=$ATMDIR/gfs.t00z.sfcf288.nemsio
SFCG09=$ATMDIR/gdas.t00z.sfcf291.nemsio
L2RWBUFR=$ATMDIR/nexrad_2018092300_fv3.t00z_drw.bufr
#L2RWBUFR=$ATMDIR/nexrad_2018092300_fv3.t00z_drw.bufr.KGRK
FIXgsi=$BASEDIR/fix/fix_gsi
CRTM_ROOT=
GSI_EXE=$BASEDIR/exec/global_gsi.x
GSI_NAMELIST=
ATMANL=gfs.t00z.atmf288.nemsio.anl
######################################################


NEMSIOGET=/gpfs/hps/nco/ops/nwpara/global_shared.v14.0.0.8/exec/nemsio_get
NLN="/bin/ln -sf"
NCP="/bin/cp"
NMV="/bin/mv"


# Get header information from Guess files
LONB=$($NEMSIOGET $ATMGES dimx | grep -i "dimx" | awk -F"= " '{print $2}' | awk -F" " '{print $1}')
LATB=$($NEMSIOGET $ATMGES dimy | grep -i "dimy" | awk -F"= " '{print $2}' | awk -F" " '{print $1}')
LEVS=$($NEMSIOGET $ATMGES dimz | grep -i "dimz" | awk -F"= " '{print $2}' | awk -F" " '{print $1}')
#JCAP=$($NEMSIOGET $ATMGES jcap | grep -i "jcap" | awk -F"= " '{print $2}' | awk -F" " '{print $1}')
JCAP=$((res*2-2))
echo "LEVS: $LEVS"

# Get dimension information based on CASE
res=$(echo $CASE | cut -c2-)
JCAP_CASE=$((res*2-2))
LATB_CASE=$((res*2))
LONB_CASE=$((res*4))
#JCAP_A=${JCAP_A:-$JCAP}
JCAP_A=$JCAP_CASE
LONA=${LONA:-$LONB}
LATA=${LATA:-$LATB}
NLON_A=${NLON_A:-$LONA}
NLAT_A=${NLAT_A:-$(($LATA+2))}
imp_physics=11

# Obs diag
RUN_SELECT=${RUN_SELECT:-"NO"}
USE_SELECT=${USE_SELECT:-"NO"}
USE_RADSTAT=${USE_RADSTAT:-"NO"}
SELECT_OBS=${SELECT_OBS:-${COMOUT}/${APREFIX}obsinput}
GENDIAG=${GENDIAG:-"NO"}
DIAG_SUFFIX=${DIAG_SUFFIX:-""}
DIAG_COMPRESS=${DIAG_COMPRESS:-"NO"}
DIAG_TARBALL=${DIAG_TARBALL:-"NO"}
USE_CFP=${USE_CFP:-"NO"}


# Set script / GSI control parameters
DOHYBVAR=${DOHYBVAR:-"NO"}
NMEM_ENKF=${NMEM_ENKF:-0}
export DONST="YES"
NST_GSI=${NST_GSI:-0}
NSTINFO=${NSTINFO:-0}
ZSEA1=${ZSEA1:-0}
ZSEA2=${ZSEA2:-0}
FAC_DTL=${FAC_DTL:-1}
FAC_TSL=${FAC_TSL:-1}
TZR_QC=${TZR_QC:-1}
USE_READIN_ANL_SFCMASK=${USE_READIN_ANL_SFCMASK:-.false.}
SMOOTH_ENKF=${SMOOTH_ENKF:-"YES"}
DOIAU=${DOIAU:-"NO"}
DO_CALC_INCREMENT=${DO_CALC_INCREMENT:-"YES"}
INCREMENTS_TO_ZERO=${INCREMENTS_TO_ZERO:-"'NONE'"}


echo $ATMGES
echo "$res $JCAP_CASE $LATB_CASE $LONB_CASE $NLON_A $NLAT_A $LONB $LATB $LEVS"

mkdir -p $DATA
cd $DATA

##############################################################
# Fixed files
RTMFIX=$NWROOT/lib/crtm/${crtm_ver}/fix
BERROR=${FIXgsi}/Big_Endian/global_berror.l${LEVS}y${NLAT_A}.f77
SATANGL=${FIXgsi}/global_satangbias.txt
SATINFO=${FIXgsi}/global_satinfo.txt
RADCLOUDINFO=${FIXgsi}/cloudy_radiance_info.txt
ATMSFILTER=${FIXgsi}/atms_beamwidth.txt
ANAVINFO=${FIXgsi}/global_anavinfo.l${LEVS}.txt.w
CONVINFO=${FIXgsi}/global_convinfo.txt
RADARLIST=${FIXgsi}/radar_list
INSITUINFO=${FIXgsi}/global_insituinfo.txt
OZINFO=${FIXgsi}/global_ozinfo.txt
PCPINFO=${FIXgsi}/global_pcpinfo.txt
AEROINFO=${FIXgsi}/global_aeroinfo.txt
SCANINFO=${FIXgsi}/global_scaninfo.txt
HYBENSINFO=${FIXgsi}/global_hybens_info.l${LEVS}.txt
OBERROR=${FIXgsi}/prepobs_errtable.global


$NLN $BERROR       berror_stats
$NLN $SATANGL      satbias_angle
$NLN $SATINFO      satinfo
$NLN $RADCLOUDINFO cloudy_radiance_info.txt
$NLN $ATMSFILTER   atms_beamwidth.txt
$NLN $ANAVINFO     anavinfo
$NLN $CONVINFO     convinfo
$NLN $RADARLIST    radar_list
$NLN $INSITUINFO   insituinfo
$NLN $OZINFO       ozinfo
$NLN $PCPINFO      pcpinfo
$NLN $AEROINFO     aeroinfo
$NLN $SCANINFO     scaninfo
$NLN $HYBENSINFO   hybens_info
$NLN $OBERROR      errtable


##############################################################


$NLN $L2RWBUFR l2rwbufr

$NLN $ATMG03 sigf03
$NLN $ATMGES sigf06
$NLN $ATMG09 sigf09

$NLN $SFCG03 sfcf03  
$NLN $SFCGES sfcf06  
$NLN $SFCg09 sfcf09  
$NLN $ATMANL siganl


#Create global_gsi namelist
cat > gsiparm.anl << EOF
&SETUP
  miter=2,
  niter(1)=100,niter(2)=100,
  niter_no_qc(1)=50,niter_no_qc(2)=0,
  write_diag(1)=.true.,write_diag(2)=.false.,write_diag(3)=.true.,
  qoption=2,
  gencode=0,deltim=94,
  factqmin=0.5,factqmax=0.005,
  iguess=-1,
  tzr_qc=1,
  oneobtest=.false.,retrieval=.false.,l_foto=.false.,
  use_pbl=.false.,use_compress=.true.,nsig_ext=12,gpstop=50.,
  use_gfs_nemsio=.true.,sfcnst_comb=.true.,
  use_readin_anl_sfcmask=.false.,
  lrun_subdirs=.true.,
  crtm_coeffs_path='./crtm_coeffs/',
  newpc4pred=.true.,adp_anglebc=.true.,angord=4,passive_bc=.true.,use_edges=.false.,
  diag_precon=.true.,step_start=1.e-3,emiss_bc=.true.,nhr_obsbin=3,
  cwoption=3,imp_physics=$imp_physics,lupp=.true.,
/
&GRIDOPTS
  !JCAP_B=$JCAP,JCAP=$JCAP_A,NLAT=$NLAT_A,NLON=$NLON_A,nsig=$LEVS,
  JCAP_B=766,JCAP=766,NLAT=770,NLON=1536,nsig=64,
  regional=.false.,global_l2rw=.true.,nlayers(63)=3,nlayers(64)=6,
/
&BKGERR
  vs=0.7,
  hzscl=1.7,0.8,0.5,
  hswgt=0.45,0.3,0.25,
  bw=0.0,norsp=4,
  bkgv_flowdep=.true.,bkgv_rewgtfct=1.5,
  bkgv_write=.false.,
  cwcoveqqcov=.false.,
/
&ANBKGERR
  anisotropic=.false.,
/
&JCOPTS
  ljcdfi=.false.,alphajc=0.0,ljcpdry=.true.,bamp_jcpdry=5.0e7,
/
&STRONGOPTS
  tlnmc_option=2,nstrong=1,nvmodes_keep=8,period_max=6.,period_width=1.5,
/
&OBSQC
  dfact=0.75,dfact1=3.0,noiqc=.true.,oberrflg=.false.,c_varqc=0.02,
  use_poq7=.true.,qc_noirjaco3_pole=.true.,vqc=.true.,
  aircraft_t_bc=.false.,biaspredt=1000.0,upd_aircraft=.false.,cleanup_tail=.true.,
  vadwnd_l2rw_qc=.false.,
/
&OBS_INPUT
  dmesh(1)=145.0,dmesh(2)=150.0,dmesh(3)=100.0,time_window_max=3.0,
/
OBS_INPUT::
!  dfile         dtype       dplat       dsis                dval    dthin dsfcalc
   l2rwbufr      rw          null        l2rw                0.0     0     0
::
&SUPEROB_RADAR
   del_azimuth=5,del_elev=.25,del_range=5000.,del_time=.125,elev_angle_max=20.,minnum=50,range_max=100000.,
   l2superob_only=.false.,
/
&LAG_DATA
/
&HYBRID_ENSEMBLE
  l_hyb_ens=.false.,
  generate_ens=.false.,
  beta_s0=0.125,readin_beta=.false.,
  s_ens_h=800.,s_ens_v=-0.8,readin_localization=.true.,
  aniso_a_en=.false.,oz_univ_static=.false.,uv_hyb_ens=.true.,
  ensemble_path='./ensemble_data/',
  ens_fast_read=.true.,
/
&RAPIDREFRESH_CLDSURF
  dfi_radar_latent_heat_time_period=30.0,
/
&CHEM
/
&SINGLEOB_TEST
  maginnov=1.0,
  magoberr=1.0,
  oneob_type='rw',
  oblat=30.72,oblon=262.62,obpres=850.,obdattim=$CDATE,obhourset=0.,
  sstn='KGRK',
  anel_rw=00.00,
  anaz_rw=00.00,
  range_rw=1000.,
  learthrel_rw=.true.,
/
&NST
  nst_gsi=3,
  nstinfo=4,fac_dtl=1,fac_tsl=1,zsea1=0,zsea2=0,
/
EOF
#cat gsiparm.anl

##############################################################
#  Make atmospheric analysis
$NCP $GSIEXEC $DATA/gsi.x
export npe_node_anal=2
export npe_anal=160
export depth_anal=2

export OMP_NUM_THREADS=12
echo "$APRUN_GSI"

job="gfs_anl"
logfile="gfs_anl.log"
queue="dev"
account="FV3GFS-T2O"
(( n=$npe_anal*$OMP_NUM_THREADS ))
(( ptile=$OMP_NUM_THREADS*$depth_anal ))
echo $n $ptile
ulimit -S -s unlimited 
ulimit -S -w ulimited
ulimit -a
#set -x
APRUN_GSI="aprun -j 1 -n $npe_anal -N $npe_node_anal -d $depth_anal -cc depth"

#bsub -J $job -o $logfile -q $queue -P $account \
#     -W 0:30 -M 1024 \
#      -extsched 'CRAYLINUX[]' \
#     -R "1*{select[craylinux && !vnode]} + $n*{select[craylinux && vnode]span[ptile=$ptile]}" \
#     $APRUN_GSI ./gsi.x > stdout  2>&1
$APRUN_GSI ./gsi.x > stdout  2>&1


##################################################################
#  run time error check
##################################################################
error=$?

if [ ${error} -ne 0 ]; then
  echo "ERROR: GSI crashed  Exit status=${error}"
  exit ${error}
fi

# Copy the output to more understandable names
ln -s stdout      stdout.anl.${ANAL_TIME}
#ln -s ${ATMANL}   wrfanl.${ANAL_TIME}
ln -s fort.201    fit_p1.${ANAL_TIME}
ln -s fort.202    fit_w1.${ANAL_TIME}
ln -s fort.203    fit_t1.${ANAL_TIME}
ln -s fort.204    fit_q1.${ANAL_TIME}
ln -s fort.207    fit_rad1.${ANAL_TIME}

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#

loops="01 03"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

#  Collect diagnostic files for obs types (groups) below
   listall="conv amsua_metop-a mhs_metop-a hirs4_metop-a hirs2_n14 msu_n14 \
          sndr_g08 sndr_g10 sndr_g12 sndr_g08_prep sndr_g10_prep sndr_g12_prep \
          sndrd1_g08 sndrd2_g08 sndrd3_g08 sndrd4_g08 sndrd1_g10 sndrd2_g10 \
          sndrd3_g10 sndrd4_g10 sndrd1_g12 sndrd2_g12 sndrd3_g12 sndrd4_g12 \
          hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 \
          amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua \
          goes_img_g08 goes_img_g10 goes_img_g11 goes_img_g12 \
          pcp_ssmi_dmsp pcp_tmi_trmm sbuv2_n16 sbuv2_n17 sbuv2_n18 \
          omi_aura ssmi_f13 ssmi_f14 ssmi_f15 hirs4_n18 amsua_n18 mhs_n18 \
          amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_las_f16 \
          ssmis_uas_f16 ssmis_img_f16 ssmis_env_f16"
   for type in $listall; do
      count=0
      if [[ -f pe0000.${type}_${loop} ]]; then
         count=`ls pe*${type}_${loop}* | wc -l`
      fi
      if [[ $count -gt 0 ]]; then
         cat pe*${type}_${loop}* > diag_${type}_${string}.${ANAL_TIME}
      fi
   done
done

#  Clean working directory to save only important files
ls -l * > list_run_directory
if [ ${if_clean} = clean ]; then
  echo ' Clean working directory after GSI run'
  rm -f *Coeff.bin     # all CRTM coefficient files
  rm -f pe0*           # diag files on each processor
  rm -f obs_input.*    # observation middle files
#  rm -f siganl sigf03  # background middle files
  rm -f fsize_*        # delete temperal file for bufr size
fi

exit 0

