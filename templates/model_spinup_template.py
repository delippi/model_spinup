import matplotlib
matplotlib.use('Agg')   # Need this to generate figs when not running an Xserver (e.g. via PBS/LSF)
import matplotlib.pyplot as plt
import os,sys
import numpy as np
from netCDF4 import Dataset

datapath="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NATURE-2018091100-2018091800/gfs.20180911/00/"
fhr=0
finc=3
i=0
KE=[]
fcsthour=[]
fmax=240

varname="@varname@"
SDATE="@SDATE@"

while (fhr <= fmax):
   filename="gfs.t00z.atmf{:03d}.nc4".format(fhr); print(filename)
   sys.stdout.flush()
   data_in=os.path.join(datapath,filename)
   fnd = Dataset(data_in,mode='r')

   if(varname=='ugrdmidlayer' or varname=='tmpmidlayer' or varname=='spfhmidlayer'):
      KE.append(0.5*(np.abs(fnd.variables[varname][0,:,:,:])).sum(dtype='float')**2)

   if(varname=='pressfc'):
      KE.append(0.5*(np.abs(fnd.variables[varname][0,:,:])).sum(dtype='float')**2)

   fcsthour.append(fhr)
   fhr+=finc
   i+=1
   fnd.close()



###################################
fig = plt.figure(1,figsize=(10,6))#
fig_title_fontsize=18             #
xy_label_fontsize=16              #
tick_label_fontsize=14            #
legend_fontsize=8.8               #
dot_size=50                       #
l_dot_size=7                      #
linewidth=3                       #
###################################
ax = fig.add_subplot(111)
cticks=np.arange(0,fmax+3,3).tolist()


if(varname=='ugrdmidlayer'):
  color='#000000'
  label='TKE(ugrd)'
if(varname=='tmpmidlayer'):
  color='#ff0044'
  label='TKE(tmp)'
if(varname=='pressfc'):
  color='#55ff00'
  label='TKE(psfc)'
if(varname=='spfhmidlayer'):
  color='#00aaff'
  label='TKE(spfh)'

ax.plot(fcsthour,KE,color=color,marker='o',markersize=l_dot_size,label=label,linewidth=linewidth,linestyle='-')
ax.set_xticks(cticks[::4])
leg=plt.legend(fontsize=legend_fontsize,ncol=4,scatterpoints=1,loc='lower left')
plt.grid('on')
title=plt.suptitle("FV3GFS Model Spinup "+SDATE,fontsize=fig_title_fontsize,x=0.5,y=0.95)
plt.xlabel("Forecast Hour",fontsize=xy_label_fontsize)
plt.ylabel("Total Kinetic Energy",fontsize=xy_label_fontsize)

leg.get_frame().set_alpha(0.9)
plt.savefig('../figs/'+SDATE+'_TKE_'+varname+'.png')




