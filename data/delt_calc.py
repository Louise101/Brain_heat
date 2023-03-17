# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

xmax=0.4#2.91
ymax=0.4#2.69
zmax=0.4#1.81

numpointsx=80# 250
numpointsy=80#231
numpointsz=80#155

dx = (2. * xmax * 1e-2) / (numpointsx + 2.)
dy = (2. * ymax * 1e-2) / (numpointsy + 2.)
dz = (2. * zmax * 1e-2) / (numpointsz + 2.) 

constd = (1./dx**2) + (1./dy**2) + (1./dz**2)

waterContent=0.75
proteinContent = 1. - waterContent

currentDensity = 1000. / (waterContent + 0.649*proteinContent) 

getSkinThermalCond = currentDensity * (6.28-4*waterContent + 1.17-4*proteinContent)

getSkinHeatCap = 1000.*(4.2*waterContent + 1.09*proteinContent)

kappatmp = getSkinThermalCond
alphatmp = kappatmp / (currentDensity* getSkinHeatCap)

delt= 1. / (1.*alphatmp*constd)

print(delt)