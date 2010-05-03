import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class MAP():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName          

    # Map
    xilinx_map = moduleList.env.Command(
      [ xilinx_apm_name + '_map.ncd', xilinx_apm_name + '.pcf' ],
      moduleList.getAllDependencies('NGD'),
      [ SCons.Script.Delete(xilinx_apm_name + '_map.map'),
        SCons.Script.Delete(xilinx_apm_name + '_map.mrp'),
        SCons.Script.Delete(xilinx_apm_name + '_map.ncd'),
        SCons.Script.Delete(xilinx_apm_name + '_map.ngm'),
        SCons.Script.Delete(xilinx_apm_name + '_map.psr'),
        'map -cm balanced -timing ' + moduleList.smartguide + ' -t ' + moduleList.env['DEFS']['COST_TABLE'] + ' ' +  moduleList.env['DEFS']['MAP_OPTIONS'] + ' -logic_opt on -ol high -register_duplication -retiming on -pr b -c 100 -p ' + fpga_part_xilinx + ' -o $TARGET $SOURCE ' + xilinx_apm_name + '.pcf' ])

    SCons.Script.Clean(xilinx_map, moduleList.compileDirectory + '/xilinx_device_details.xml')

    moduleList.topModule.moduleDependency['MAP'] = [xilinx_map]
