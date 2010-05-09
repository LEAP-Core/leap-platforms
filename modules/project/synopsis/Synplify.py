import os
import re
import SCons.Script  
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

def _generate_synplify_include(file):
  #Check for relative/absolute path
  directoryFix = ''
  if(not re.search('^\s*/',file)):
    directoryFix = '$env(BUILD_DIR)/'

  type = 'unknown'

  if(re.search('\.ngc\s*$',file)):
    type = 'ngc'

  if(re.search('\.v\s*$',file)):
    type = 'verilog'

  if(re.search('\.vhdl\*$',file)):
    type = 'vhdl'

  if(re.search('\.vhd\s*$',file)):
    type = 'vhdl'

  return 'add_file -'+ type +' \"'+ directoryFix + file + '\"\n'




class Synthesize(ProjectDependency):
  def __init__(self, moduleList):

    # need to eventually break this out into a seperate function
    # first step - modify prj options file to contain any generated wrappers
    prjFile = open('config/' + moduleList.apmName + '.synplify.prj','r');  
    newPrjFile = open('config/' + moduleList.apmName + '.modified.synplify.prj','w');  

    #build unified sdc 
    combinedSDC = open(moduleList.compileDirectory + '/' + moduleList.apmName + '.sdc','w')
    for sdc in moduleList.getAllDependencies('SDC'):
      sdcIn = open(sdc,'r')
      print 'reading SDC' + sdc + '\n' 
      combinedSDC.write(sdcIn.read()+'\n')
    combinedSDC.close();

    #first dump the wrapper files to the new prj 

    for module in moduleList.moduleList:    
      print 'writing wrappers:' + module.wrapperName() +'\n'
      newPrjFile.write('add_file -verilog \"$env(BUILD_DIR)/hw/'+module.buildPath + '/.bsc/' + module.wrapperName()+'.v\"\n');      

    # now dump all the 'VERILOG' 
    fileArray = moduleList.getAllDependencies('VERILOG') + moduleList.getAllDependencies('VHD')# + moduleList.getAllDependencies('NGC')  
    for file in fileArray:
      if(type(file) is str):
        newPrjFile.write(_generate_synplify_include(file))        
      else:
        print type(file)
        print "is not a string"

    #Set up new implementation
  
    #once we get synth boundaries up, this will be needed only for top level
    newPrjFile.write('set_option -disable_io_insertion 0\n');

    newPrjFile.write('impl -add ' + moduleList.topModule.wrapperName()  + ' -type fpga\n')

    #dump synplify options file
    print 'Dumping old prj file\n'
    newPrjFile.write(prjFile.read())


    # add in global constraints files 
    newPrjFile.write('add_file -constraint  \"$env(BUILD_DIR)/' + moduleList.compileDirectory + '/' + moduleList.apmName + '.sdc\"\n')
    newPrjFile.write('set_option -constraint -enable  \"$env(BUILD_DIR)/' + moduleList.compileDirectory + '/' + moduleList.apmName + '.sdc\"\n')

    #write the tail end of the options file to actually do the synthesis
     
    newPrjFile.write('set_option -top_module '+ moduleList.topModule.wrapperName()+'\n')
    newPrjFile.write('project -result_file \"$env(BUILD_DIR)/' + moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.edf\"\n')
    
    newPrjFile.write('project -run constraint_check\n');
    newPrjFile.write('project -run synthesis\n');
    newPrjFile.write('impl -active \"'+ moduleList.topModule.wrapperName() +'\"\n');


    newPrjFile.close();
    prjFile.close();

    # Synplify sometimes produces a synplify .ucf, but we should 
    # write to it, incase synplify doesn't.
    synplifyUCF = moduleList.compileDirectory + '/synplicity.ucf'
    moduleList.topModule.moduleDependency['UCF'] = [synplifyUCF] + moduleList.topModule.moduleDependency['UCF']    


    # Now that we've set up the world let's compile

    top_netlist = moduleList.env.Command(
        [moduleList.compileDirectory + '/' +  moduleList.topModule.wrapperName() + '.edf'] + [synplifyUCF],
        moduleList.topModule.moduleDependency['VERILOG'] + ['config/' + moduleList.apmName + '.synplify.prj'] ,
        [ SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '.srr'),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '_xst.xrpt'), 
          'touch ' + synplifyUCF,         
          'synplify_pro -batch config/' + moduleList.apmName + '.modified.synplify.prj' ])
    SCons.Script.Clean(top_netlist,moduleList.compileDirectory + '/' + moduleList.apmName + '.srp')
    SCons.Script.Clean(top_netlist,'config/' + moduleList.apmName + '.modified.synplify.prj')

    moduleList.topModule.moduleDependency['SYNTHESIS'] = top_netlist

