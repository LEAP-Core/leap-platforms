import os
import SCons.Script
from model import  *
from xilinx_ucf import *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class PostSynthesize():
  def __init__(self, moduleList):

    self.fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    self.xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Concatenate UCF files
    UCF(moduleList)

    moduleList.dump()

    if len(moduleList.env['DEFS']['GIVEN_BMMS']) != 0:
      xilinx_bmm = moduleList.env.Command(
        self.xilinx_apm_name + '.bmm',
        Utils.clean_split(moduleList.env['DEFS']['GIVEN_BMMS'], sep = ' '),
        'cat $SOURCES > $TARGET')
    #./ works around crappy xilinx parser
      bmm = ' -bm ./' + self.xilinx_apm_name + '.bmm' 
    else:
      xilinx_bmm = ''
      bmm = ''

    moduleList.topModule.moduleDependency['BMMS'] = [xilinx_bmm]
      
    xilinx_ngd = moduleList.env.Command(
      self.xilinx_apm_name + '.ngd',
      moduleList.getAllDependencies('SYNTHESIS') + moduleList.getAllDependencies('UCFS') + moduleList.getAllDependencies('BMMS'),
      [ SCons.Script.Delete(self.xilinx_apm_name + '.bld'),
        SCons.Script.Delete(self.xilinx_apm_name + '_ngdbuild.xrpt'),
        # Xilinx project files are created automatically by Xilinx tools, but not
        # needed for command line tools.  The project files may be corrupt due
        # to parallel invocation of xst.  Until we figure out how to move them
        # or guarantee their safety, just delete them.
        SCons.Script.Delete('xlnx_auto_0.ise'),
        SCons.Script.Delete('xlnx_auto_0_xdb'),
        'ngdbuild -p ' + self.fpga_part_xilinx + ' -sd ' + moduleList.env['DEFS']['ROOT_DIR_HW_MODEL'] + ' -uc ' + self.xilinx_apm_name + '.ucf ' + bmm + ' $SOURCE $TARGET',
        SCons.Script.Move(moduleList.compileDirectory + '/netlist.lst', 'netlist.lst') ])

    moduleList.topModule.moduleDependency['NGD'] = [xilinx_ngd]
      
    SCons.Script.Clean(xilinx_ngd, moduleList.compileDirectory + '/netlist.lst')

    # Alias for everything up to map...
    #moduleList.env.Alias('xst', xilinx_ngd + SW_EXE)


    #
    # Use a cached post par ncd to guide map and par?  This is off by default since
    # the smart guide option can make place & route fail when it otherwise would have
    # worked.  It doesn't always improve run time, either.  To turn on smart guide
    # either define the environment variable USE_SMARTGUIDE or set
    # USE_SMARTGUIDE on the scons command line to a non-zero value.
    #
#     smartguide_cache_dir = env['DEFS']['WORKSPACE_ROOT'] + '/var/xilinx_ncd'
#     smartguide_cache_file = APM_NAME + '_par.ncd'
#     if not os.path.isdir(smartguide_cache_dir):
#       os.mkdir(smartguide_cache_dir)
        
#     if ((int(ARGUMENTS.get('USE_SMARTGUIDE', 0)) or env['ENV'].has_key('USE_SMARTGUIDE')) and
#         (FindFile(APM_NAME + '_par.ncd', [smartguide_cache_dir]) != None)):
#       smartguide = ' -smartguide ' +  smartguide_cache_dir + '/' + smartguide_cache_file
#     else:
#       smartguide = ''
          

#     # Map
#     xilinx_map = env.Command(
#       [ self.xilinx_apm_name + '_map.ncd', self.xilinx_apm_name + '.pcf' ],
#       xilinx_ngd,
#       [ Delete(self.xilinx_apm_name + '_map.map'),
#         Delete(self.xilinx_apm_name + '_map.mrp'),
#         Delete(self.xilinx_apm_name + '_map.ncd'),
#         Delete(self.xilinx_apm_name + '_map.ngm'),
#         Delete(self.xilinx_apm_name + '_map.psr'),
#         'map -cm balanced -timing ' + smartguide + ' -t ' + env['DEFS']['COST_TABLE'] + ' ' +  env['DEFS']['MAP_OPTIONS'] + ' -logic_opt on -ol high -register_duplication -retiming on -pr b -c 100 -p ' + self.fpga_part_xilinx + ' -o $TARGET $SOURCE ' + self.xilinx_apm_name + '.pcf' ])

#     Clean(xilinx_map, moduleList.compileDirectory + '/xilinx_device_details.xml')




#     # Place and route
#     xilinx_par = env.Command(
#       self.xilinx_apm_name + '_par.ncd',
#       xilinx_map,
#       [ Delete(self.xilinx_apm_name + '_par.pad'),
#         Delete(self.xilinx_apm_name + '_par.par'),
#         Delete(self.xilinx_apm_name + '_par.ptwx'),
#         Delete(self.xilinx_apm_name + '_par.unroutes'),
#         Delete(self.xilinx_apm_name + '_par.xpi'),
#         Delete(self.xilinx_apm_name + '_par_pad.csv'),
#         Delete(self.xilinx_apm_name + '_par_pad.txt'),
#         'par -w -ol high ' + smartguide + ' -t ' + env['DEFS']['COST_TABLE'] + ' ' + self.xilinx_apm_name + '_map.ncd $TARGET ' + self.xilinx_apm_name + '.pcf',
#         Copy(smartguide_cache_dir + '/' + smartguide_cache_file, '$TARGET') ])


#     # Generate the FPGA timing report -- this report isn't built by default.  Use
#     # the "timing" target to generate it
#     xilinx_trce = env.Command(
#       self.xilinx_apm_name + '_par.twr',
#       [ xilinx_par, self.xilinx_apm_name + '.pcf' ],
#       'trce -e 100 $SOURCES -o $TARGET')
    


#     if len(env['DEFS']['GIVEN_ELFS']) != 0:
#       elf = ' -bd ' + str.join(' -bd ',clean_split(env['DEFS']['GIVEN_ELFS'], sep = ' '))
#     else:
#       elf = ''




#     # Generate the FPGA image
#     xilinx_bit = env.Command(
#       self.xilinx_apm_name + '_par.bit',
#       [ 'config/' + APM_NAME + '.ut', xilinx_par],
#       [ Delete('config/signature.sh'),
#         'bitgen ' + elf + ' -f $SOURCES $TARGET ' + self.xilinx_apm_name + '.pcf' ])
    
#     Depends(xilinx_bit, clean_split(env['DEFS']['GIVEN_ELFS'], sep = ' '));

#     # Generate the signature for the FPGA image
#     signature = env.Command(
#       'config/signature.sh',
#       xilinx_bit,
#       [ '@echo \'#!/bin/sh\' > $TARGET',
#         '@echo signature=\\"' + APM_NAME + '-`md5sum $SOURCE | sed \'s/ .*//\'`\\" >> $TARGET' ])
    
#     #
#     # The final step must leave a few files in well-known locations since they are
#     # used by the run scripts.  APM_NAME is the software side, if there is one.
#     #
#     loader = env.Command(
#       APM_NAME + '_hw.errinfo',
#       signature + SW_EXE + xilinx_trce,
#       [ '@ln -fs ' + SW_EXE_OR_TARGET + ' ' + APM_NAME,
#         Delete(APM_NAME + '_hw.exe'),
#         Delete(APM_NAME + '_hw.vexe'),
#         '@echo "++++++++++++ Post-Place & Route ++++++++"',
#         '@' + awb_resolver('tools/scripts/hasim-xilinx-summary') + ' ' +
#         self.xilinx_apm_name + '_map.map ' +
#         self.xilinx_apm_name + '_par.par ' +
#         APM_NAME + '_hw.errinfo' ])
    
#     env.Alias('bit', loader)
