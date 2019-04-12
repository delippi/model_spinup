from netCDF4 import Dataset,netcdftime,num2date
import numpy as np
import os


dir00="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00/"
dir06="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06/"
atmf009="atmf009.tile5.nc"
sfcf009="sfcf000.tile5.nc"
atmf003="atmf003.tile5.nc"
sfcf003="sfcf003.tile5.nc"

atmf009=os.path.join(dir00,atmf009)
sfcf009=os.path.join(dir00,sfcf009)
atmf003=os.path.join(dir06,atmf003)
sfcf003=os.path.join(dir06,sfcf003)

atmf009fnd=Dataset(atmf009,mode='r')
sfcf009fnd=Dataset(sfcf009,mode='r')
atmf003fnd=Dataset(atmf003,mode='r')
sfcf003fnd=Dataset(sfcf003,mode='r')

lats=384
lons=384

var3d=[
#'pfull',
#'phalf',
#'delp',
#'liq_wat',
#'nhpres',
#'o3mr',
'sphum',
'temp',
'ucomp',
'vcomp',
'vvel',
]

atmf009var=np.zeros(shape=(64,lats,lons))
sfcf009var=np.zeros(shape=(lats,lons))
atmf003var=np.zeros(shape=(64,lats,lons))
sfcf003var=np.zeros(shape=(lats,lons))

for v3 in var3d:
    atmf009var[:,:,:]=atmf009fnd.variables[v3][0,:,:,:]
    atmf003var[:,:,:]=atmf003fnd.variables[v3][0,:,:,:]
    diff=atmf009var-atmf003var
    print(v3,np.min(diff),np.max(diff))

exit()
for v2 in var2d:
    sfcf009var[:,:]=sfcf009fnd.variables[v2][0,:,:]
    sfcf003var[:,:]=sfcf003fnd.variables[v2][0,:,:]
    diff=sfcf009var-sfcf003var
    print(v2,np.min(diff),np.max(diff))

for s2 in sfc2d:
    sfcf009var[:,:]=sfcf009fnd.variables[s2][0,:,:]
    sfcf003var[:,:]=sfcf003fnd.variables[s2][0,:,:]
    diff=sfcf009var-sfcf003var
    print(s2,np.min(diff),np.max(diff))
