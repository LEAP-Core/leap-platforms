import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class UCF():
  def __init__(self, moduleList):

    self.xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Concatenate UCF files
    xilinx_ucf = moduleList.env.Command(
      self.xilinx_apm_name + '.ucf',
      Utils.clean_split(moduleList.env['DEFS']['GIVEN_UCFS'], sep = ' '),
      'cat $SOURCES > $TARGET')

    moduleList.topModule.moduleDependency['UCFS'] = [xilinx_ucf]
