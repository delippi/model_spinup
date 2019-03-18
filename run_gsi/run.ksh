#!/bin/ksh

cat /dev/null > gfs_anl.log

bsub < run_gsi.ksh
