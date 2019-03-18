#!/bin/ksh

fhr=288
typeset -Z3 fhr
EXP=FreeRunLow2-2018091100-2018091800

htar -xvf /NCEPDEV/emc-meso/5year/Donald.E.Lippi/rw_FV3GFS/$EXP.tar $EXP/gfs.t00z.atmf$fhr.nemsio



