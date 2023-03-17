#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Feb 17 15:49:57 2023

@author: lf58
"""

import matplotlib.pyplot as plt
import matplotlib.colors as color
import numpy as np
import math as math
import matplotlib.image as mpimg
import csv

#[z,y,x]
depth=[]

fd = open('1temp-t2w-152-500-400-1.748-1.748-1.748.dat', 'rb')
fd = open('heat2w-152-500-400-1.748-1.748-1.748.dat', 'rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
data=np.fromfile(file=fd, dtype=np.double).reshape(154,154,154)
fd.close()
#data=datain#np.flip(datain)

fd = open('1jmean-t2w-152-500-400-1.748-1.748-1.748.dat', 'rb')


#fd= open('1rhokap-t2w-152-500-400-1.748-1.748-1.748.dat','rb')
#fd= open('jmean_slice_test.dat','rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
datj=np.fromfile(file=fd, dtype=np.double).reshape(152,152,152)
fd.close()
#data=datain#np.flip(datain)



#fd= open('jmean_slice_test.dat','rb')
#fd= open('temp_slice_test.dat','rb')
#fd = open('60o21_g21_ox39_thresh560.dat', 'rb')
#dat=np.fromfile(file=fd, dtype=np.double).reshape(2,80,80)
#fd.close()
#data=datain#np.flip(datain)

#dslice=dat[1,:,:]
dslice=data[:,76,:]
#dslice=datj[76,:,:]

plt.imshow(dslice)
plt.colorbar()
plt.savefig('temp_image.png',format='png',dpi=1200, bbox_inches='tight')
plt.show()