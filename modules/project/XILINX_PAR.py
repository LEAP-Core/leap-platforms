import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class PAR():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Place and route
    xilinx_par = moduleList.env.Command(
      xilinx_apm_name + '_par.ncd',
      moduleList.getAllDependencies('MAP'),
      [ SCons.Script.Delete(xilinx_apm_name + '_par.pad'),
        SCons.Script.Delete(xilinx_apm_name + '_par.par'),
        SCons.Script.Delete(xilinx_apm_name + '_par.ptwx'),
        SCons.Script.Delete(xilinx_apm_name + '_par.unroutes'),
        SCons.Script.Delete(xilinx_apm_name + '_par.xpi'),
        SCons.Script.Delete(xilinx_apm_name + '_par_pad.csv'),
        SCons.Script.Delete(xilinx_apm_name + '_par_pad.txt'),
        'par -w -ol high ' + moduleList.smartguide + ' -t ' + moduleList.env['DEFS']['COST_TABLE'] + ' ' + xilinx_apm_name + '_map.ncd $TARGET ' + xilinx_apm_name + '.pcf',
        SCons.Script.Copy(moduleList.smartguide_cache_dir + '/' + moduleList.smartguide_cache_file, '$TARGET') ])

    moduleList.topModule.moduleDependency['PAR'] = [xilinx_par]
