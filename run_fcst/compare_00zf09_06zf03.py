from netCDF4 import Dataset,netcdftime,num2date
import numpy as np
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap, cm, maskoceans
import ncepy

'''
cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/00
nemsio2nc4.py --nemsio gdas.t00z.atmf009.nemsio
nemsio2nc4.py --nemsio gdas.t00z.sfcf009.nemsio

cd /gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/06
nemsio2nc4.py --nemsio gdas.t06z.atmf003.nemsio
nemsio2nc4.py --nemsio gdas.t06z.sfcf003.nemsio
'''


cyc1="06"
cyc2="12"

dir00="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/"+cyc1+"/"
dir06="/gpfs/hps2/ptmp/Donald.E.Lippi/fv3gfs_dl2rw/2018091100/FreeRunLow5-2018091100-2018091800/gdas.20180911/"+cyc2+"/"
atmf009="gdas.t"+cyc1+"z.atmf009.nc4"; sfcf009="gdas.t"+cyc1+"z.sfcf009.nc4"
atmf003="gdas.t"+cyc2+"z.atmf003.nc4"; sfcf003="gdas.t"+cyc2+"z.sfcf003.nc4"

atmf009=os.path.join(dir00,atmf009); sfcf009=os.path.join(dir00,sfcf009)
atmf003=os.path.join(dir06,atmf003); sfcf003=os.path.join(dir06,sfcf003)

atmf009fnd=Dataset(atmf009,mode='r'); sfcf009fnd=Dataset(sfcf009,mode='r')
atmf003fnd=Dataset(atmf003,mode='r'); sfcf003fnd=Dataset(sfcf003,mode='r')

fnd=atmf009fnd

lats=768; lons=1536

sfc2d=[
'alnsfsfc','alnwfsfc','alvsfsfc','alvwfsfc',
'cnwatsfc','crainsfc','f10m10m','facsfsfc',
'facwfsfc','ffhhsfc','ffmmsfc','fricvsfc',
'icecsfc','icetksfc','landsfc','orogsfc',
'snoalbsfc','sfcrsfc','shdmaxsfc','shdminsfc',
'soill0_10cmdown','soill10_40cmdow','soill40_100cmdo','soill100_200cmd',
'sltypsfc','soilw0_10cmdown','soilw10_40cmdow','soilw40_100cmdo',
'soilw100_200cmd','snodsfc','sotypsfc','spfh2m',
'tmp0_10cmdown','tmp10_40cmdown','tmp40_100cmdown','tmp100_200cmdow',
'tg3sfc','tisfc','tmp2m','tmpsfc',
'tprcpsfc','vegsfc','vtypesfc','weasdsfc',
'c0sfc','cdsfc','dconvsfc','dtcoolsfc',
'qrainsfc','trefsfc','w0sfc','wdsfc',
'xssfc','xtsfc','xttssfc','xusfc',
'xvsfc','xzsfc','xztssfc','zcsfc',
]

var2d=['pressfc','hgtsfc',]

var3d=[
'ugrdmidlayer','vgrdmidlayer',
'dzdtmidlayer','delzmidlayer',
'tmpmidlayer' ,'dpresmidlayer',
'spfhmidlayer','clwmrmidlayer',
'rwmrmidlayer','icmrmidlayer',
'snmrmidlayer','grlemidlayer',
'o3mrmidlayer','cld_amtmidlayer',
]
var3d=['ugrdmidlayer']

atmf009var=np.zeros(shape=(64,lats,lons)); sfcf009var=np.zeros(shape=(lats,lons))
atmf003var=np.zeros(shape=(64,lats,lons)); sfcf003var=np.zeros(shape=(lats,lons))

#import datetime
#time009=atmf009fnd.variables['time'][:]
#time003=atmf003fnd.variables['time'][:]
#tunits009=atmf009fnd.variables['time'].units
#tunits003=atmf003fnd.variables['time'].units
#tcal009=atmf003fnd.variables['time'].calendar
#tcal003=atmf003fnd.variables['time'].calendar

#datevar009=num2date(time009,units=tunits009,calendar=tcal009)
#datevar003=num2date(time003,units=tunits003,calendar=tcal003)

#print(datevar009,datevar003)

if(True):
 for v3 in var3d:
    atmf009var[:,:,:]=atmf009fnd.variables[v3][0,:,:,:]
    atmf003var[:,:,:]=atmf003fnd.variables[v3][0,:,:,:]
    diff=atmf009var-atmf003var
    arr=np.where(diff==np.max(diff))
    levmax=arr[0][0]
    print(arr)
    print(v3,np.min(diff),np.max(diff),np.shape(diff))

if(False):
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


if(False):
  exit()


outputdir="/gpfs/hps3/emc/meso/save/Donald.E.Lippi/model_spinup/run_fcst"
dom="CONUS"
proj="gnom"
proj="cyl"
varname='ugrdmidlayer'
fig = plt.figure(figsize=(8,8))
ax = plt.subplot(111)
llcrnrlon,llcrnrlat,urcrnrlon,urcrnrlat,res=ncepy.corners_res(dom,proj=proj)
if(proj=="cyl"):
  llcrnrlon,llcrnrlat,urcrnrlon,urcrnrlat,res=-180,-80,180,80,'c'
lon_0=-95.0
lat_0=25.0
m = Basemap(llcrnrlon=llcrnrlon,llcrnrlat=llcrnrlat,urcrnrlon=urcrnrlon,urcrnrlat=urcrnrlat,
               projection=proj, lat_0=lat_0,lon_0=lon_0,resolution=res,ax=ax)

parallels = np.arange(-80.,80,10.)
meridians = np.arange(-180,180.,10.)

m.drawcoastlines(linewidth=1.25*0.5)
m.drawcountries(linewidth=1.25*0.5)
lons  = fnd.variables['lon'][:]
lats  = fnd.variables['lat'][:]
lons=lons-180
nlon=len(lons)
keep_ax_lst = ax.get_children()[:]
lon,lat=np.meshgrid(lons,lats)
xi,yi = m(lon,lat)

############### plot_ functions ###########################################
def plot_ugrd(var_n): 
    """zonal wind diff"""
    longname="ugrd diff"; units="m/s"
    #clevs=[-.1,-.05,-.01,0,.01,.05,.1]
    clevs=[-5,-4,-3,-2,-1,0,1,2,3,4,5]
    cticks=clevs
    
    title="zonal wind diff level "+str(levmax)
    cm='jet'
    return(var_n,clevs,cticks,cm,units,longname,title)

def plot_Dictionary():
    dispatcher={'ugrdmidlayer':plot_ugrd,}
    return dispatcher


dispatcher=plot_Dictionary()
var_n=fnd.variables[str(varname)][0,20,:,:]
var_n=np.roll(var_n,nlon/2,axis=1)
function=dispatcher[varname]
var_n,clevs,cticks,cm,units,longname,title=function(var_n)

cs = m.contourf(xi,yi,diff[levmax,:,:],clevs,cmap=cm,extend='both')
cbar = m.colorbar(cs,location='bottom',pad="5%",extend="both",ticks=cticks)
cbar.ax.tick_params(labelsize=8.5)
cbar.set_label(varname+": "+longname+" ["+str(units)+"]")
plt.title(title)

plt.xticks(visible=False)
plt.yticks(visible=False)
#plt.savefig(outputdir+'/gfs.t%sz.%s_v%s_atmf%s_%s.png' % (cyc,pdy+cyc,valtime,fhr,varname),dpi=250, bbox_inches='tight')
plt.savefig(outputdir+'/diff.png',dpi=250, bbox_inches='tight')

print("fig is located: "+outputdir)

plt.close('all')





