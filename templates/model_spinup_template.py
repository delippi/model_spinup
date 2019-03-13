import matplotlib
matplotlib.use('Agg')   # Need this to generate figs when not running an Xserver (e.g. via PBS/LSF)
import matplotlib.pyplot as plt
import os,sys
import numpy as np
from netCDF4 import Dataset

datapath1="@datapath1@"
datapath2="@datapath2@"
fhr=@fhr@
finc=@finc@
i=0
KE=[]
fcsthour=[]
fmax=@fmax@
RES=@RES@

varname="@varname@"
SDATE="@SDATE@"

RootMeanSquareDiff=@RootMeanSquareDiff@
Energy=@Energy@
threeD_var=False
twoD_var=False
velocity=False
nemsio=False
grb2=False
if(varname=='ugrdmidlayer'):
   threeD_var=True; velocity=True; nemsio=True; grb2=False; color='#000000'; label='wind'
if(varname=='UGRD_P0_L100_GGA0'):
   threeD_var=True; velocity=True; nemsio=False; grb2=True; color='#000000'; label='wind'

if(varname=='tmpmidlayer'):
   threeD_var=True; velocity=False; nemsio=True; grb2=False; color='#ff0044'; label='tmp'
if(varname=='TMP_P0_L100_GGA0'):
   threeD_var=True; velocity=False; nemsio=False; grb2=True; color='#ff0044'; label='tmp'

if(varname=='spfhmidlayer'):
   threeD_var=True; velocity=False; nemsio=True; grb2=False; color='#00aaff'; label='spfh'
if(varname=='SPFH_P0_L100_GGA0'):
   threeD_var=True; velocity=False; nemsio=False; grb2=True; color='#00aaff'; label='spfh'

if(varname=='pressfc'):
   twoD_var=True; velocity=False; nemsio=True; grb2=False; color='#ff8c00'; label='psfc'
if(varname=='PRES_P0_L1_GGA0'):
   twoD_var=True; velocity=False; nemsio=False; grb2=True; color='#ff8c00'; label='psfc'

if(grb2):
   plevel=500 #hPa
   plevels=[ .4,  1,  2,  3,  5,  7, 10, 15, 20, 30,\
             40, 50, 70,100,125,150,175,200,225,250,\
            275,300,325,350,375,400,425,450,475,500,\
            525,550,575,600,625,650,675,700,725,750,\
            775,800,825,850,875,900,925,950,975,1000]
   model_level=plevels.index(plevel) #return index of 500 mb

if(RES == 384): lats=768; lons=1536
if(RES == 768): lats=1536; lons=3072


while (fhr <= fmax):
   #Experiment 1 - regular ICs from gdas analysis
   if(nemsio): filename1="gfs.t00z.atmf{:03d}.nc4".format(fhr)
   if(grb2):   filename1="gfs.t00z.master.grb2f{:03d}.nc4".format(fhr)
   data_in1=os.path.join(datapath1,filename1)
   fnd1 = Dataset(data_in1,mode='r')

   #Experiment 2 - perturbed ICs from enkf mem080 analysis
   if(nemsio): filename2="gfs.t00z.atmf{:03d}.nc4".format(fhr)
   if(grb2):   filename2="gfs.t00z.master.grb2f{:03d}.nc4".format(fhr)
   data_in2=os.path.join(datapath2,filename2)
   fnd2 = Dataset(data_in2,mode='r')

   print(filename1,filename2); sys.stdout.flush()


   #Three dimensional, vector varaiables
   if(threeD_var and velocity): #e.g., ugrd
      #Eq 1. Wind Speed = sqrt(u**2 + v**2)
      #Eq 2. Kinetic Energy = sum(0.5 * var**2)
      #Eq 3. KE for wind = 0.5(u**2 + v**2)
      #Eq 4. RMSD = sqrt( 1/N * sqrt([(u1-u2)**2 - (v1-v2)**2])**2) == sqrt( 1/N * [(u1-u2)**2 - (v1-v2)**2] )

      if(nemsio): 
         varname1='ugrdmidlayer'
         varname2='vgrdmidlayer'

         if(Energy): #ENERGY
            u_diff=np.zeros(shape=(64,lats,lons)).astype('float16')
            v_diff=np.zeros(shape=(64,lats,lons)).astype('float16')
            ke=np.zeros(shape=(64,lats,lons)).astype('float32')
            for lev in range(64): #loop over levels to not max out memory in batch job
               u_diff[lev,:,:]=(fnd1.variables[varname1][0,lev,:,:].astype('float16') \
                              - fnd2.variables[varname1][0,lev,:,:].astype('float16'))
               v_diff[lev,:,:]=(fnd1.variables[varname2][0,lev,:,:].astype('float16') \
                              - fnd2.variables[varname2][0,lev,:,:].astype('float16'))
               ke[lev,:,:]=0.5*(u_diff[lev,:,:]**2 + v_diff[lev,:,:]**2) #Eq 3. KE for wind
            del u_diff #done with this variable for this forecast hour. detlete.
            del v_diff #done with this variable for this forecast hour. detlete.
            KE.append(ke.sum(dtype='float32')) #append total kinetic energy to KE list
            del ke #done with this variable for this forecast hour. detlete.
            figname=SDATE+"_TE_Wind"
            figtitle="FV3GFS Total Energy Difference"+SDATE
            ylabel="Total Energy"

         if(RootMeanSquareDiff): #RMSD
            u_diff=np.zeros(shape=(lats,lons)).astype('float32')
            v_diff=np.zeros(shape=(lats,lons)).astype('float32')
            spd_diff=np.zeros(shape=(lats,lons)).astype('float32')
            lev=50
            lev=lev-1
            u_diff[:,:]=(fnd1.variables[varname1][0,lev,:,:].astype('float32') \
                       - fnd2.variables[varname1][0,lev,:,:].astype('float32'))
            v_diff[:,:]=(fnd1.variables[varname2][0,lev,:,:].astype('float32') \
                       - fnd2.variables[varname2][0,lev,:,:].astype('float32'))
            spd_diff[:,:]=u_diff[:,:]**2 + v_diff[:,:]**2 #sqrt cancelled by **2 later
            del u_diff #done with this variable for this forecast hour. detlete.
            del v_diff #done with this variable for this forecast hour. detlete.
            rmsd=np.sqrt(spd_diff.mean(dtype='float32'))
            del spd_diff #done with this variable for this forecast hour. detlete.
            KE.append(rmsd)
            figname=SDATE+"_RMSD_Wind"
            figtitle="FV3GFS RMSD model level "+str(lev+1)+" "+SDATE
            ylabel="Root Mean Square Difference"


      if(grb2):
         varname1='UGRD_P0_L100_GGA0'
         varname2='VGRD_P0_L100_GGA0'

         if(Energy): #ENERGY
            u_diff=np.zeros(shape=(lats,lons)).astype('float32')
            v_diff=np.zeros(shape=(lats,lons)).astype('float32')
            ke=np.zeros(shape=(lats,lons)).astype('float32')
            lev=model_level
            u_diff[:,:]=(fnd1.variables[varname1][lev,:,:].astype('float32') \
                       - fnd2.variables[varname1][lev,:,:].astype('float32'))
            v_diff[:,:]=(fnd1.variables[varname2][lev,:,:].astype('float32') \
                       - fnd2.variables[varname2][lev,:,:].astype('float32'))
            ke[:,:]=0.5*(u_diff[:,:]**2 + v_diff[:,:]**2) #Eq 3. KE for wind
            del u_diff #done with this variable for this forecast hour. detlete.
            del v_diff #done with this variable for this forecast hour. detlete.
            KE.append(ke.sum(dtype='float32')) #append total kinetic energy to KE list
            del ke #done with this variable for this forecast hour. detlete.
            figname=SDATE+"_TE_"+str(plevel)+"-hPa_"+varname
            figtitle="FV3GFS TED"+str(plevel)+"-hPa "+SDATE
            ylabel="Total Energy Difference"

         if(RootMeanSquareDiff): #RMSD
            u_diff=np.zeros(shape=(lats,lons)).astype('float32')
            v_diff=np.zeros(shape=(lats,lons)).astype('float32')
            spd_diff=np.zeros(shape=(lats,lons)).astype('float32')
            lev=model_level
            u_diff[:,:]=(fnd1.variables[varname1][lev,:,:].astype('float32') \
                       - fnd2.variables[varname1][lev,:,:].astype('float32'))
            v_diff[:,:]=(fnd1.variables[varname2][lev,:,:].astype('float32') \
                       - fnd2.variables[varname2][lev,:,:].astype('float32'))
            spd_diff[:,:]=u_diff[:,:]**2 + v_diff[:,:]**2 #sqrt cancelled by **2 later
            del u_diff #done with this variable for this forecast hour. detlete.
            del v_diff #done with this variable for this forecast hour. detlete.
            rmsd=np.sqrt(spd_diff.mean(dtype='float32'))
            del spd_diff #done with this variable for this forecast hour. detlete.
            KE.append(rmsd)
            figname=SDATE+"_RMSD_"+str(plevel)+"-hPa_"+varname
            figtitle="FV3GFS RMSD "+str(plevel)+"-hPa "+SDATE
            ylabel="Root Mean Square Difference"




   #Three dimensional, non-vector varaiables
   if(threeD_var and not velocity): #e.g., tmp, spfh

      if(nemsio):
         if(Energy): #Energy
            #Eq 3. Energy = sum( 0.5 * var**2)
            var_diff=np.zeros(shape=(64,lats,lons)).astype('float32')
            ke=np.zeros(shape=(64,lats,lons)).astype('float32')
            for lev in range(64): #loop over levels to not max out memory in batch job
               var_diff[lev,:,:]=(fnd1.variables[varname][0,lev,:,:].astype('float32') \
                                - fnd2.variables[varname][0,lev,:,:].astype('float32'))
               ke[lev,:,:]=0.5*(var_diff[lev,:,:]**2) #Eq 3. Energy
            del var_diff #done with this variable for this forecast hour. detlete.
            KE.append(ke.sum(dtype='float32'))
            del ke #done with this variable for this forecast hour. detlete.
         if(RootMeanSquareDiff): #RMSD
            var_diff=np.zeros(shape=(lats,lons)).astype('float32')
            lev=model_level
            var_diff[:,:]=(fnd1.variables[varname][0,lev,:,:].astype('float32') \
                         - fnd2.variables[varname][0,lev,:,:].astype('float32'))
            var_diff[:,:]=var_diff[:,:]**2
            rmsd=np.sqrt(var_diff.mean(dtype='float32'))
            del var_diff #done with this variable for this forecast hour. detlete.
            KE.append(rmsd)
            figname=SDATE+"_RMSD_"+str(plevel)+"-hPa_"+varname
            figtitle="FV3GFS RMSD "+str(plevel)+"-hPa "+SDATE
            ylabel="Root Mean Square Difference"

      if(grb2):
         if(Energy): #Energy
            #Eq 3. Energy = sum( 0.5 * var**2)
            var_diff=np.zeros(shape=(lats,lons)).astype('float32')
            ke=np.zeros(shape=(lats,lons)).astype('float32')
            lev=model_level
            var_diff[lev,:,:]=(fnd1.variables[varname][lev,:,:].astype('float32') \
                             - fnd2.variables[varname][lev,:,:].astype('float32'))
            ke[lev,:,:]=0.5*(var_diff[lev,:,:]**2) #Eq 3. Energy
            del var_diff #done with this variable for this forecast hour. detlete.
            KE.append(ke.sum(dtype='float32'))
            del ke #done with this variable for this forecast hour. detlete.
         if(RootMeanSquareDiff): #RMSD
            var_diff=np.zeros(shape=(lats,lons)).astype('float32')
            lev=model_level
            var_diff[:,:]=(fnd1.variables[varname][lev,:,:].astype('float32') \
                         - fnd2.variables[varname][lev,:,:].astype('float32'))
            var_diff[:,:]=var_diff[:,:]**2
            rmsd=np.sqrt(var_diff.mean(dtype='float32'))
            del var_diff #done with this variable for this forecast hour. detlete.
            KE.append(rmsd)
            figname=SDATE+"_RMSD_"+str(plevel)+"-hPa_"+varname
            figtitle="FV3GFS RMSD "+str(plevel)+"-hPa "+SDATE
            ylabel="Root Mean Square Difference"



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


ax.plot(fcsthour,KE,color=color,marker='o',markersize=l_dot_size,label=label,linewidth=linewidth,linestyle='-')
xlabels=cticks[::8]
ax.set_xticks(xlabels)
ax.set_xticklabels(xlabels,rotation=45)
leg=plt.legend(fontsize=legend_fontsize,ncol=4,scatterpoints=1,loc='lower left')
plt.grid('on')
title=plt.suptitle(figtitle,fontsize=fig_title_fontsize,x=0.5,y=0.95)
plt.xlabel("Forecast Hour",fontsize=xy_label_fontsize)
plt.ylabel(ylabel,fontsize=xy_label_fontsize)

leg.get_frame().set_alpha(0.9)


plt.savefig('../figs/'+figname+'.png')




