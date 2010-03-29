import os
import SCons.Script  
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class Synthesize(ProjectDependency):
  def __init__(self, moduleList):

    # first step - modify prj to contain any generated wrappers
    prjFile = open('config/' + moduleList.apmName + '.synplify.prj','r');  
    newPrjFile = open('config/' + moduleList.apmName + '.modified.synplify.prj','w');  

    #first dump the wrapper files to the new prj 
    for module in moduleList.moduleList:    
      print "writing wrappers:" . module.synthTop
      newPrjFile.write('add_file -verilog "$env(BUILD_DIR)/'+module.synthTop+'\n');      

    #and dump the old file contents
    print "Dumping old prj file\n"
    newPrjFile.write(prjFile.read());

    newPrjFile.close();
    prjFile.close();


    # second step build a unified SDC
    combinedSDC = open(moduleList.compileDirectory + '/' + moduleList.apmName + '.sdc','w')
    for sdc in moduleList.givenSDCs:
      sdcIn = open(sdc,'r')
      combinedSDC.write(sdcIn.read()+'\n')
         
    # Now that we've set up the world let's compile

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' +  moduleList.apmName + '.edf',
        moduleList.topVerilog + moduleList.givenVs + ['config/' + moduleList.apmName + '.modified.synplify.prj'] ,
        [ SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '.srr'),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName  + '_xst.xrpt'),
          'synplify_pro -batch config/' + moduleList.apmName + '.modified.synplify.prj' ])
    SCons.Script.Clean(top_netlist,moduleList.compileDirectory + '/' + moduleList.apmName + '.srp')
    SCons.Script.Clean(top_netlist,'config/' + moduleList.apmName + '.modified.synplify.prj')

    self.topDependency = top_netlist

