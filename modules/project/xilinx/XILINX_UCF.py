import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class UCF():
  def __init__(self, moduleList):

    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Concatenate UCF files
    for ucf in  moduleList.topModule.moduleDependency['UCF']:
      print 'found ucf: ' + ucf + '\n'
    xilinx_ucf = moduleList.env.Command(
      xilinx_apm_name + '.ucf',
      moduleList.topModule.moduleDependency['UCF'],
      'cat $SOURCES > $TARGET')

    moduleList.topModule.moduleDependency['UCF'] = [xilinx_ucf]
