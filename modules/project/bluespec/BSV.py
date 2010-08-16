import os
import sys
import re
import SCons.Script
from model import  *



#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path
# This is going to recursively build all the bsvs
class BSV():

  def __init__(self, moduleList):
   
    TMP_BSC_DIR = moduleList.env['DEFS']['TMP_BSC_DIR']

    moduleList.env['DEFS']['CWD_REL'] = moduleList.env['DEFS']['ROOT_DIR_HW_MODEL']

    #should we be building in events? 
    if (getEvents(moduleList) == 0):
       bsc_events_flag = '-D HASIM_EVENTS_ENABLED=False'
    else:
       bsc_events_flag = '-D HASIM_EVENTS_ENABLED=True'

    moduleList.env['DEFS']['BSC_FLAGS_VERILOG'] += ' ' + bsc_events_flag

    moduleList.env['DEFS']['BSC_FLAGS'] = moduleList.env['DEFS']['BSC_FLAGS_VERILOG']
    env = moduleList.env
    moduleList.env.Export('env')
    # this should really be a crawl of the bluespec tree
    # probably in that case we can avoid a lot of synthesis time
    wrapper_v = moduleList.env.SConscript([moduleList.env['DEFS']['ROOT_DIR_HW_MODEL'] + '/SConscript'])

    moduleList.env.BuildDir(TMP_BSC_DIR, '.', duplicate=0)
    moduleList.env['ENV']['BUILD_DIR'] = moduleList.env['DEFS']['BUILD_DIR']  # need to set the builddir for synplify
