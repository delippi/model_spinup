import matplotlib
matplotlib.use('Agg')   # Need this to generate figs when not running an Xserver (e.g. via PBS/LSF)
import matplotlib.pyplot as plt
import os,sys
import numpy as np
from netCDF4 import Dataset

datapath1="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NATURE-2018091100-2018091800/gfs.20180911/00/"
datapath2="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/NODA-2018091100-2018091800/gfs.20180911/06"
fhr=0
finc=3
i=0
KE=[]
fcsthour=[]
fmax=240
fmax=141

varname="@varname@"
SDATE="@SDATE@"


threeD_var=False
twoD_var=False
velocity=False
if(varname=='ugrdmidlayer'):                           threeD_var=True; velocity=True
if(varname=='tmpmidlayer' or varname=='spfhmidlayer'): threeD_var=True; velocity=False
if(varname=='pressfc'):                                twoD_var=True;   velocity=False


while (fhr <= fmax):
   #NATURE - 6 hr fcst = 0 hr fcst of NODA 
   filename1="gfs.t00z.atmf{:03d}.nc4".format(fhr+6)
   data_in1=os.path.join(datapath1,filename1)
   fnd1 = Dataset(data_in1,mode='r')

   #NODA
   filename2="gfs.t06z.atmf{:03d}.nc4".format(fhr)
   data_in2=os.path.join(datapath2,filename2)
   fnd2 = Dataset(data_in2,mode='r')

   print(filename1,filename2); sys.stdout.flush()


   #Three dimensional, vector varaiables
   if(threeD_var and velocity): #e.g., ugrd
      #Eq 1. Wind Speed = sqrt(u**2 + v**2)
      #Eq 2. Kinetic Energy = sum(0.5 * var**2)
      varname1='ugrdmidlayer'
      varname2='vgrdmidlayer'
      u_diff=np.zeros(shape=(64, 1536, 3072)).astype('float16')
      v_diff=np.zeros(shape=(64, 1536, 3072)).astype('float16')
      spd=np.zeros(shape=(64, 1536, 3072)).astype('float32')
      print("checkpoint 1/3"); sys.stdout.flush()

      for lev in range(64): #loop over levels to not max out memory in batch job
         u_diff[lev,:,:]=(fnd1.variables[varname1][0,lev,:,:].astype('float16') \
                        - fnd2.variables[varname1][0,lev,:,:].astype('float16'))
         v_diff[lev,:,:]=(fnd1.variables[varname2][0,lev,:,:].astype('float16') \
                        - fnd2.variables[varname2][0,lev,:,:].astype('float16'))
         spd[lev,:,:]=np.sqrt(u_diff[lev,:,:]**2 + v_diff[lev,:,:]**2) #Eq 1. Wind Speed

      print("checkpoint 2/3"); sys.stdout.flush()
      del u_diff #done with this variable for this forecast hour. detlete.
      del v_diff #done with this variable for this forecast hour. detlete.

      ke=np.zeros(shape=(64, 1536, 3072)).astype('float32')
      for lev in range(64): #loop over levels to not max out memory in batch job
         ke[lev,:,:]=0.5*(spd[lev,:,:]**2) #Eq 2. Kinetic Energy
      del spd #done with this variable for this forecast hour. detlete.

      KE.append(ke.sum(dtype='float32')) #append total kinetic energy to KE list
      print("checkpoint 3/3"); sys.stdout.flush() 
      del ke #done with this variable for this forecast hour. detlete.



   #Three dimensional, non-vector varaiables
   if(threeD_var and not velocity): #e.g., tmp, spfh
      #Eq 3. Energy = sum( 0.5 * var**2)
      var_diff=np.zeros(shape=(64, 1536, 3072)).astype('float32')
      ke=np.zeros(shape=(64, 1536, 3072)).astype('float32')

      for lev in range(64): #loop over levels to not max out memory in batch job
         var_diff[lev,:,:]=(fnd1.variables[varname][0,lev,:,:].astype('float32') \
                          - fnd2.variables[varname][0,lev,:,:].astype('float32'))
         ke[lev,:,:]=0.5*(var_diff[lev,:,:]**2) #Eq 3. Energy
      del var_diff #done with this variable for this forecast hour. detlete.

      KE.append(ke.sum(dtype='float32'))
      del ke #done with this variable for this forecast hour. detlete.



   #Two dimensional variables
   if(twoD_var): #e.g., sfc pres
      #Eq 3. Energy = sum( 0.5 * var**2)
      var_diff=np.zeros(shape=(1536, 3072)).astype('float32')
      ke=np.zeros(shape=(1536, 3072)).astype('float32')

      var_diff[:,:]=(fnd1.variables[varname][0,:,:].astype('float32') \
                   - fnd2.variables[varname][0,:,:].astype('float32'))
      ke[:,:]=0.5*(var_diff[:,:]**2) #Eq 3. Energy
      del var_diff #done with this variable for this forecast hour. detlete.

      KE.append(ke.sum(dtype='float32'))
      del ke #done with this variable for this forecast hour. detlete.



   fcsthour.append(fhr)
   fhr+=finc
   i+=1
   fnd1.close()
   fnd2.close()



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




