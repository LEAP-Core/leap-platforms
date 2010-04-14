import os
import re
import sys
import SCons.Script
from model import  *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class PostSynthesize():
  def __init__(self, moduleList):

    altera_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName

    # assume we get a single edf now, no multiple edf
    altera_vqm = moduleList.env.Command(
      altera_apm_name + '.vqm',
      moduleList.topModule.moduleDependency['SYNTHESIS'],
      'cp $SOURCE $TARGET')

    newPrjFile = open(altera_apm_name + '.temp.qsf','w')

    newPrjFile.write('set_global_assignment -name TOP_LEVEL_ENTITY ' + moduleList.topModule.wrapperName() + '\n')

    # vqm from synplify
    newPrjFile.write('set_global_assignment -name VQM_FILE ' + moduleList.apmName + '.vqm\n')

    # add the verilogs of the files generated by quartus system builder
    for v in Utils.clean_split(moduleList.env['DEFS']['GIVEN_ALTERAVS'], sep = ' ') :
      newPrjFile.write('set_global_assignment -name VERILOG_FILE ' + moduleList.env['DEFS']['BUILD_DIR'] + '/' + v +'\n'); 

    newPrjFile.write('set_global_assignment -name SDC_FILE ' + moduleList.topModule.wrapperName() + '.scf\n')
    newPrjFile.close()

    # Concatenate altera QSF files
    altera_qsf = moduleList.env.Command(
      altera_apm_name + '.qsf',
      [altera_apm_name + '.temp.qsf'] + Utils.clean_split(moduleList.env['DEFS']['GIVEN_QSFS'], sep = ' '),
      ['cat $SOURCES > $TARGET',
       'rm ' + altera_apm_name + '.temp.qsf'])

   # generate sof
    altera_sof = moduleList.env.Command(
      altera_apm_name + '.sof',
      altera_vqm + altera_qsf,
      ['quartus_map ' + altera_apm_name,
       'quartus_fit ' + altera_apm_name,
       'quartus_sta ' + altera_apm_name,
       'quartus_asm ' + altera_apm_name])

    moduleList.topModule.moduleDependency['LOADER'] = [altera_sof]
