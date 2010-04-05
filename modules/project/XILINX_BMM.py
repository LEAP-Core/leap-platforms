import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class BMM():
  def __init__(self, moduleList):

    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    if len(moduleList.env['DEFS']['GIVEN_BMMS']) != 0:
      xilinx_bmm = moduleList.env.Command(
        xilinx_apm_name + '.bmm',
        Utils.clean_split(moduleList.env['DEFS']['GIVEN_BMMS'], sep = ' '),
        'cat $SOURCES > $TARGET')
    #./ works around crappy xilinx parser
      bmm = ' -bm ./' + xilinx_apm_name + '.bmm' 
    else:
      xilinx_bmm = ''
      bmm = ''

    moduleList.topModule.moduleDependency['XILINX_BMM'] = [xilinx_bmm]
    moduleList.topModule.moduleDependency['BMM'] = [bmm]
