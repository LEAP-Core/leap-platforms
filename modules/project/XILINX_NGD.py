import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class NGD():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    bmm = ''
    for i in range(len(moduleList.getAllDependencies('BMM'))):
        bmm += moduleList.getAllDependencies('BMM')[i]
    xilinx_ngd = moduleList.env.Command(
      xilinx_apm_name + '.ngd',
      moduleList.getAllDependencies('SYNTHESIS') + moduleList.getAllDependencies('UCFS') + moduleList.getAllDependencies('XILINX_BMM'),
      [ SCons.Script.Delete(xilinx_apm_name + '.bld'),
        SCons.Script.Delete(xilinx_apm_name + '_ngdbuild.xrpt'),
        # Xilinx project files are created automatically by Xilinx tools, but not
        # needed for command line tools.  The project files may be corrupt due
        # to parallel invocation of xst.  Until we figure out how to move them
        # or guarantee their safety, just delete them.
        SCons.Script.Delete('xlnx_auto_0.ise'),
        SCons.Script.Delete('xlnx_auto_0_xdb'),
        'ngdbuild -p ' + fpga_part_xilinx + ' -sd ' + moduleList.env['DEFS']['ROOT_DIR_HW_MODEL'] + ' -uc ' + xilinx_apm_name + '.ucf ' + bmm + ' $SOURCE $TARGET',
        SCons.Script.Move(moduleList.compileDirectory + '/netlist.lst', 'netlist.lst') ])

    moduleList.topModule.moduleDependency['NGD'] = [xilinx_ngd]
      
    SCons.Script.Clean(xilinx_ngd, moduleList.compileDirectory + '/netlist.lst')
