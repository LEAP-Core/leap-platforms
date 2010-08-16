import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class BITGEN():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Generate the FPGA image
    xilinx_bit = moduleList.env.Command(
      xilinx_apm_name + '_par.bit',
      [ 'config/' + moduleList.apmName + '.ut' ] + moduleList.getAllDependencies('PAR'),
      [ SCons.Script.Delete('config/signature.sh'),
        'bitgen ' + moduleList.elf + ' -f $SOURCES $TARGET ' + xilinx_apm_name + '.pcf' ])
    
    SCons.Script.Depends(xilinx_bit, Utils.clean_split(moduleList.env['DEFS']['GIVEN_ELFS'], sep = ' '));

    moduleList.topModule.moduleDependency['BIT'] = [xilinx_bit]
    moduleList.topDependency = moduleList.topDependency + [xilinx_bit]     
