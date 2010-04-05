import os
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class LOADER():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Generate the FPGA timing report -- this report isn't built by default.  Use
    # the "timing" target to generate it
    xilinx_trce = moduleList.env.Command(
      xilinx_apm_name + '_par.twr',
      moduleList.getAllDependencies('PAR') + [ xilinx_apm_name + '.pcf' ],
      'trce -e 100 $SOURCES -o $TARGET')

    moduleList.topModule.moduleDependency['TRCE'] = [xilinx_trce]

    # Generate the signature for the FPGA image
    signature = moduleList.env.Command(
      'config/signature.sh',
      moduleList.getAllDependencies('BIT'),
      [ '@echo \'#!/bin/sh\' > $TARGET',
        '@echo signature=\\"' + moduleList.apmName + '-`md5sum $SOURCE | sed \'s/ .*//\'`\\" >> $TARGET' ])
    
    moduleList.topModule.moduleDependency['SIGNATURE'] = [signature]

    #
    # The final step must leave a few files in well-known locations since they are
    # used by the run scripts.  moduleList.apmName is the software side, if there is one.
    #
    loader = moduleList.env.Command(
      moduleList.apmName + '_hw.errinfo',
      moduleList.getAllDependencies('SIGNATURE') + moduleList.swExe + moduleList.getAllDependencies('TRCE'),
      [ '@ln -fs ' + moduleList.swExeOrTarget + ' ' + moduleList.apmName,
        SCons.Script.Delete(moduleList.apmName + '_hw.exe'),
        SCons.Script.Delete(moduleList.apmName + '_hw.vexe'),
        '@echo "++++++++++++ Post-Place & Route ++++++++"',
        '@' + awb_resolver('tools/scripts/hasim-xilinx-summary') + ' ' +
        xilinx_apm_name + '_map.map ' +
        xilinx_apm_name + '_par.par ' +
        moduleList.apmName + '_hw.errinfo' ])

    moduleList.topModule.moduleDependency['LOADER'] = [loader]
