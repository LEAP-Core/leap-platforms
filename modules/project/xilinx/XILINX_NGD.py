import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class NGD():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName

    # Concatenate UCF files
    #for ucf in  moduleList.topModule.moduleDependency['UCF']:
    #  print 'ngd found ucf: ' + ucf + '\n' 
    xilinx_ucf = moduleList.env.Command(
      xilinx_apm_name + '.ucf',
      moduleList.topModule.moduleDependency['UCF'],
      'cat $SOURCES > $TARGET')

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

    xilinx_ngd = moduleList.env.Command(
      xilinx_apm_name + '.ngd',
      moduleList.getAllDependencies('SYNTHESIS') + xilinx_ucf + xilinx_bmm,
      [ SCons.Script.Delete(xilinx_apm_name + '.bld'),
        SCons.Script.Delete(xilinx_apm_name + '_ngdbuild.xrpt'),
        # Xilinx project files are created automatically by Xilinx tools, but not
        # needed for command line tools.  The project files may be corrupt due
        # to parallel invocation of xst.  Until we figure out how to move them
        # or guarantee their safety, just delete them.
        SCons.Script.Delete('xlnx_auto_0.ise'),
        SCons.Script.Delete('xlnx_auto_0_xdb'),
        'ngdbuild -aul -p ' + fpga_part_xilinx + ' -sd ' + moduleList.env['DEFS']['ROOT_DIR_HW_MODEL'] + ' -uc ' + xilinx_apm_name + '.ucf ' + bmm + ' $SOURCE $TARGET',
        SCons.Script.Move(moduleList.compileDirectory + '/netlist.lst', 'netlist.lst') ])

    moduleList.topModule.moduleDependency['NGD'] = [xilinx_ngd]
      
    SCons.Script.Clean(xilinx_ngd, moduleList.compileDirectory + '/netlist.lst')
