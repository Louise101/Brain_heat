#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 26 17:05:16 2023

@author: lf58
"""

import matplotlib.pyplot as plt
import numpy as np
import matplotlib.colors as color



fd = open('1jmean-t2w-152-500-400-1.748-1.748-1.748.dat', 'rb')
#fd= open('1rhokap-t2w-152-500-400-1.748-1.748-1.748.dat','rb')
#fd= open('jmean_slice_test.dat','rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
data=np.fromfile(file=fd, dtype=np.double).reshape(152,152,152)
fd.close()


fd= open('1rhokap-t2w-152-500-400-1.748-1.748-1.748.dat','rb')
#fd= open('jmean_slice_test.dat','rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
rho=np.fromfile(file=fd, dtype=np.double).reshape(152,152,152)
fd.close()

fd = open('1temp-t2w-152-500-400-1.748-1.748-1.748.dat', 'rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
dat=np.fromfile(file=fd, dtype=np.double).reshape(154,154,154)
fd.close()

for i in range (len(rho)):
  for j in range (len(rho[0])):
      for k in range(len(rho[0][0])):
         if (rho[i][j][k]==10.001 or rho[i][j][k]==0.020001 or rho[i][j][k]==0.39 or rho[i][j][k]==0. or rho[i][j][k]==0.006):
            data[i][j][k]=0.
            rho[i][j][k]=0.
      #      alb[i][j][k]=0.

fluslice=data[:,76,:]

flu=[]

for i in range(len(fluslice)):
    flu.append(fluslice[100,i]/10.) #W/m2 to mW/cm2


dslice=dat[:,40,:]
temp=[]

for i in range(len(dslice)):
    temp.append(dslice[100,i]) #degC
    
depth=[]
for i in range(len(temp)):
    depth.append(i*0.233) #mm
    
depth_flu=[]
for i in range(len(flu)):
    depth_flu.append(i*0.233) #mm
    
    
#plt.plot(depth_x[:36],dose_x[:36], linewidth='3', label='left')
plt.plot(depth,temp, linewidth='3', label='right')

#plt.plot(depth_x[85:105],jmean_x_depth, linestyle='dashed', color='black')
#plt.plot(jmean_x_flu,jmean_x[85:105])
#plt.plot(jmean_x_25,jmean_x[85:105])
#plt.plot(jmean_x_wall,jmean_x[84:105])
#plt.yscale('log')
plt.xlabel('depth (mm)') 
plt.ylabel('Temperature (C)')  
plt.title('z depth Temperature')
#plt.legend()
#plt.xticks(fontsize=15)
#plt.yticks(fontsize=15)
#plt.savefig('flu_wall_x_code1_right.png',format='png',dpi=1200, bbox_inches='tight')
plt.show()

#plt.plot(depth_x[:36],dose_x[:36], linewidth='3', label='left')
#plt.plot(depth_flu[8:18],flu[8:18], linewidth='3', label='right')
plt.plot(depth_flu,flu, linewidth='3', label='right')

#plt.plot(depth_x[85:105],jmean_x_depth, linestyle='dashed', color='black')
#plt.plot(jmean_x_flu,jmean_x[85:105])
#plt.plot(jmean_x_25,jmean_x[85:105])
#plt.plot(jmean_x_wall,jmean_x[84:105])
#plt.yscale('log')
plt.xlabel('depth (mm)') 
plt.ylabel('Fluence rate (mW/cm2)')  
plt.title('z depth Fluence')
#plt.legend()
#plt.xticks(fontsize=15)
#plt.yticks(fontsize=15)
#plt.savefig('flu_wall_x_code1_right.png',format='png',dpi=1200, bbox_inches='tight')
plt.show()
    
#PUT IN WATER then run!