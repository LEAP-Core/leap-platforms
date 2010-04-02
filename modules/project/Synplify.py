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

    #first dump the wrapper files to the new prj 

    for module in moduleList.moduleList:    
      print 'writing wrappers:' + module.wrapperName() +'\n'
      newPrjFile.write('add_file -verilog \"$env(BUILD_DIR)/hw/'+module.buildPath + '/.bsc/' + module.wrapperName()+'.v\"\n');      

    # now dump all the 'VERILOG' 
    fileArray = moduleList.topModule.moduleDependency['VERILOG']
    for file in fileArray:
      if(type(file) is str):
        newPrjFile.write(_generate_synplify_include(file))
        print "Adding " + _generate_synplify_include(file) + " for " + file
      else:
        print type(file)
        print "is not a string"

    #Set up new implementation
    newPrjFile.write('impl -add ' + moduleList.topModule.wrapperName()  + '-type fpga\n')

    #dump synplify options file
    print 'Dumping old prj file\n'
    newPrjFile.write(prjFile.read());


    #write the tail end of the options file to actually do the synthesis
     
    newPrjFile.write('set_option -top_module '+ moduleList.topModule.wrapperName()+'\n')
    newPrjFile.write('project -result_file \"$env(BUILD_DIR)/' + moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.edf\"\n')
    
    newPrjFile.write('project -run constraint_check\n');
    newPrjFile.write('project -run synthesis\n');
    newPrjFile.write('impl -active \"'+ moduleList.topModule.wrapperName() +'\"\n');


    newPrjFile.close();
    prjFile.close();


    # second step build a unified SDC
    combinedSDC = open(moduleList.compileDirectory + '/' + moduleList.apmName + '.sdc','w')
    for sdc in moduleList.givenSDCs:
      sdcIn = open(sdc,'r')
      combinedSDC.write(sdcIn.read()+'\n')
         
    # Now that we've set up the world let's compile

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' +  moduleList.topModule.wrapperName() + '.edf',
        moduleList.topModule.moduleDependency['VERILOG'] + ['config/' + moduleList.apmName + '.synplify.prj'] ,
        [ SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '.srr'),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '_xst.xrpt'),
          'synplify_pro -batch config/' + moduleList.apmName + '.modified.synplify.prj' ])
    SCons.Script.Clean(top_netlist,moduleList.compileDirectory + '/' + moduleList.apmName + '.srp')
    SCons.Script.Clean(top_netlist,'config/' + moduleList.apmName + '.modified.synplify.prj')

    moduleList.topModule.moduleDependency['SYNTHESIS'] = top_netlist

