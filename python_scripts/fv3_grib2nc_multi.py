from timeit import default_timer as timer
tic=timer()
import sys,os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap, cm, maskoceans
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes, mark_inset
import multiprocessing
import numpy as np
from netCDF4 import Dataset
#import colormap
from netcdftime import utime
from datetime   import datetime,timedelta
import scipy
import ncepy
#Necessary to generate figs when not running an Xserver (e.g. via PBS)
plt.switch_backend('agg')
import pdb

######################   USER DEFINED SETTINGS    ############################################
CDUMP='gdas' #gdas or gfs

global pdy,cyc,valpdy,valcyc,valtime,fhr

experiment_name=[]; filename=[]; datadir=[]; pdy=[]; cyc=[]; valpdy=[]; valcyc=[]; valtime=[]; fhr=[]
num_args=9

print("\n \n \n")
print("python starting...")
exp_count=int(sys.argv[1])


#try:
for exp in range(exp_count):
      print(exp)
      experiment_name.append(str(sys.argv[2 +exp*num_args]))
      filename.append(str(       sys.argv[3 +exp*num_args]))
      datadir.append( str(       sys.argv[4 +exp*num_args]))
      pdy.append(     str(int(   sys.argv[5 +exp*num_args])))
      cyc.append(     str(int(   sys.argv[6 +exp*num_args])).zfill(2))
      valpdy.append(  str(int(   sys.argv[7 +exp*num_args])))
      valcyc.append(  str(int(   sys.argv[8 +exp*num_args])).zfill(2))
      valtime.append( str(int(   sys.argv[9 +exp*num_args])))
      fhr.append(     str(int(   sys.argv[10+exp*num_args])).zfill(3))



outputdir="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/plots/figs/288"
print(filename,pdy,cyc,valpdy,valcyc,valtime)
data_in=[]
for i in range(exp_count): data_in.append(os.path.join(datadir[i],filename[i]))   # name of analysis file
dom="CONUS"                                               # domain (can be CONUS, SC, etc.)
proj="gnom"                                               # map projection
proj="cyl"
varnames=[                                                # uncomment the desired variables below
#        'TMP_P0_L100_GGA0',
#        'SPFH_P0_L100_GGA0',
#        'RH_P0_L100_GGA0',
#        'UGRD_P0_L100_GGA0',
#        'VGRD_P0_L100_GGA0',
#        'VVEL_P0_L100_GGA0',
#        'DZDT_P0_L100_GGA0',
#        'ABSV_P0_L100_GGA0',
        'HGT_P0_L100_GGA0',
         ]
######################   USER DEFINED SETTINGS    ############################################
fig = plt.figure(figsize=(8,8))
ax = plt.subplot(111)

llcrnrlon,llcrnrlat,urcrnrlon,urcrnrlat,res=ncepy.corners_res(dom,proj=proj)
if(proj=="cyl"):
  llcrnrlon,llcrnrlat,urcrnrlon,urcrnrlat,res=-180,-80,180,80,'c'
lon_0=-95.0
lat_0=25.0
offsetup=0.
offsetright=0.
m = Basemap(llcrnrlon=llcrnrlon+offsetright,   llcrnrlat=llcrnrlat+offsetup,
               urcrnrlon=urcrnrlon+offsetright,  urcrnrlat=urcrnrlat+offsetup,
               projection=proj, lat_0=lat_0,lon_0=lon_0,
               resolution=res,ax=ax)

parallels = np.arange(-80.,80,10.)
meridians = np.arange(-180,180.,10.)
m.drawcoastlines(linewidth=1.25*0.5)
m.drawcountries(linewidth=1.25*0.5)

def mkplot(varname):
    print("mkplot - "+str(multiprocessing.current_process()))
    fnd=[]; varnames2d=[]; xi=[]; yi=[]
    for i in range(exp_count):
       print(data_in[i])
       fnd.append(Dataset(data_in[i],mode='r'))
       varnames2d.append(fnd[i].variables.keys())
       global lons,lats
       lons  = fnd[i].variables['lon_0'][:]
       lats  = fnd[i].variables['lat_0'][:]
       lons=lons-180
       nlon=len(lons)
       keep_ax_lst = ax.get_children()[:]
       lon,lat=np.meshgrid(lons,lats)
       xj,yj = m(lon,lat)
       xi.append(xj)
       yi.append(yj)


    dispatcher=plot_Dictionary()
    global model_level,plevel
    if(varname=='TMP_P0_L100_GGA0'): plevel=850 #hPa
    if(varname=='HGT_P0_L100_GGA0'): plevel=500 #hPa
    plevels=[ .4,  1,  2,  3,  5,  7, 10, 15, 20, 30,\
              40, 50, 70,100,125,150,175,200,225,250,\
             275,300,325,350,375,400,425,450,475,500,\
             525,550,575,600,625,650,675,700,725,750,\
             775,800,825,850,875,900,925,950,975,1000]
    model_level=plevels.index(plevel) #return index of 500 mb
    var_n=[]
    for i in range(exp_count):
       var_n.append(fnd[i].variables[str(varname)][model_level,:,:])
       var_n[i]=np.roll(var_n[i],nlon/2,axis=1)
       print(np.max(var_n[i]),np.min(var_n[i]))

    try: # Doing it this way means we only have to supply a corresponding definition for cm,clevs,etc.
       function=dispatcher[varname]
       for i in range(exp_count): var_n[i],clevs,cticks,cm,units,longname,title=function(var_n[i])
    except KeyError:
       raise ValueError("invalid varname:"+varname)

    for i in range(exp_count):
        print i
        if(i==9):
           color='gray'
           cs1=m.contour(xi[i],yi[i],var_n[i],clevs,colors=color,linestyles='-')
           ax.plot(0,0,color=color,label="NATURE")
           plt.clabel(cs1,inline=1,fontsize=6,colors=color,fmt='%1.0f')
        if(i==1):
           color='blue'
           cs2=m.contour(xi[i],yi[i],var_n[i],clevs,colors=color,linestyles='-')
           ax.plot(0,0,color=color,label="NODA")
           plt.clabel(cs2,inline=1,fontsize=6,colors=color,fmt='%1.0f')
        if(i==9):
           color='maroon'
           cs3=m.contour(xi[i],yi[i],var_n[i],clevs,colors=color,linestyles='-')
           ax.plot(0,0,color=color,label="NEXRAD")
           plt.clabel(cs3,inline=1,fontsize=6,colors=color,fmt='%1.0f')
        if(i==3):
           color='green'
           cs3=m.contour(xi[i],yi[i],var_n[i],clevs,colors=color,linestyles='-')
           ax.plot(0,0,color=color,label="NODA (stopstart)")
           plt.clabel(cs3,inline=1,fontsize=6,colors=color,fmt='%1.0f')


    leg=ax.legend(fontsize=8,ncol=1,scatterpoints=1,loc='lower left')
    leg.get_frame().set_alpha(0.9)
    plt.title(title)

    plt.xticks(visible=False)
    plt.yticks(visible=False)
    plt.savefig(outputdir+'/gfs.t%sz.%s_v%s_atmf%s_%s.png' % (cyc[2],pdy[2]+cyc[2],valtime[2],fhr[2],varname),dpi=250, bbox_inches='tight')

    print("fig is located: "+outputdir)

    plt.close('all')


############### useful functions ###########################################
def roundTime(dt=None, roundTo=60):
   """Round a datetime object to any time laps in seconds
   dt : datetime.datetime object, default now.
   roundTo : Closest number of seconds to round to, default 1 minute.
   Author: Thierry Husson 2012 - Use it as you want but don't blame me.
   """
   if dt == None : dt = datetime.datetime.now()
   seconds = (dt.replace(tzinfo=None) - dt.min).seconds
   rounding = (seconds+roundTo/2) // roundTo * roundTo
   return dt + timedelta(0,rounding-seconds,-dt.microsecond)

def gemplot(clist):
    gemlist=ncepy.gem_color_list()
    colors=[gemlist[i] for i in clist]
    cm = matplotlib.colors.ListedColormap(colors)
    return cm

############### plot_ functions ###########################################
#HGT_P0_L100_GGA0 ( lv_ISBL0, lat_0, lon_0 )

def plot_HGT_P0_L100_GGA0(var_n):
    """Geopotential Height on Isobaric Levels"""
    longname="Geopotential Height on Isobaric Levels"; units="gpm"
    var_n=var_n/10.
    clevs=np.arange(444,984,6).tolist()
    clevs=[576]
    cticks=clevs
    cm='k'
    title="%d-hPa geopotential height \n %s %sZ %sHR Fcst Valid %s %sZ" % (plevel,pdy[2],cyc[2],fhr[2],valpdy[2],valcyc[2])
    return(var_n,clevs,cticks,cm,units,longname,title)


def plot_TMP_P0_L100_GGA0(var_n):
    """Temperature on Isobaric Levels"""
    longname="Temperature on Isobaric Levels"; units="K"
    var_n=var_n#/10.
    clevs=np.arange(150,300,4).tolist()
    cticks=clevs
    cm='k'
    title="%d-hPa temperature \n %s %sZ %sHR Fcst Valid %s %sZ" % (plevel,pdy[2],cyc[2],fhr[2],valpdy[2],valcyc[2])
    return(var_n,clevs,cticks,cm,units,longname,title)

def plot_dbz(var_n):
    """reflectivity [dBz]"""
    longname="reflectivity"; units="dBZ"
    clevs=[-5,0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75] # dbz
    cticks=[-5,0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75] # dbz
    #cm=ncepy.radarmap()
    cm=mrms_radarmap_with_gray()
    if(model_level=='column max'):
        title="NATURE Composite Simulated Reflectivity \n Valid %s %sZ" % (valpdy,valcyc)
    return(var_n,clevs,cticks,cm,units,longname,title)

############### Dictionary for plot_function calls ###################################
def plot_Dictionary():
    #As fields are added to fv3 output just put those in the following dictionary
    #   according to the syntax used. Then all you have to do is create a function
    #   that defines the clevs, cm, and var_n if it requires unit conversion
    #   (e.g., plot_PRATEsfc(var_n) )
    """The purpose of this dictionary is so that for each variable name (e.g., "ALBDOsfc")
       the corresponding function is called (e.g., plot_ALBDOsfc(var_n)) to provide the
       appropriate variable specific name, units, clevs, clist, and colormap for plotting.
    """
    dispatcher={
        'TMP_P0_L100_GGA0':plot_TMP_P0_L100_GGA0,
        'HGT_P0_L100_GGA0':plot_HGT_P0_L100_GGA0,
               }
    return dispatcher

def mrms_radarmap_with_gray():
    from matplotlib import colors
    r=[0.66,0.41,0.00,0.00,0.00,0.00,0.00,0.00,1.00,0.91,1.00,1.00,0.80,0.60,1.00,0.60]
    g=[0.66,0.41,0.93,0.63,0.00,1.00,0.78,0.56,1.00,0.75,0.56,0.00,0.20,0.00,0.00,0.20]
    b=[0.66,0.41,0.93,0.96,0.96,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,1.00,0.80]
    rgb=zip(r,g,b)
    cmap=colors.ListedColormap(rgb,len(r))
    cmap.set_over(color='white')
    cmap.set_under(color='white')
    return cmap


#def Make_Zoomed_Inset_Plot():

if __name__ == '__main__':
    pool=multiprocessing.Pool(len(varnames)) # one processor per variable
    #pool=multiprocessing.Pool(8) # 8 processors for all variables. Just a little slower.
    pool.map(mkplot,varnames)
    #mkplot(varnames[0])
    toc=timer()
    time=toc-tic
    hrs=int(time/3600)
    mins=int(time%3600/60)
    secs=int(time%3600%60)
    print("Total elapsed time: "+str(toc-tic)+" seconds.")
    print("Total elapsed time: "+str(hrs).zfill(2)+":"+str(mins).zfill(2)+":"+str(secs).zfill(2))


