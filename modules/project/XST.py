import os
import sys
import SCons.Script
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class Synthesize():
  def __init__(self, moduleList):
    for module in moduleList.moduleList:    
        # we must tweak the xst files of the internal module list
        # to prevent the insertion of iobuffers
        newXSTFile = open('config/' + module.wrapperName() + '.modified.xst','w')
        oldXSTFile = open('config/' + module.wrapperName() + '.xst','r')
        newXSTFile.write(oldXSTFile.read());
        newXSTFile.write('-iobuf no\n');
        newXSTFile.close();
        oldXSTFile.close();
        w = moduleList.env.Command(
            moduleList.compileDirectory + '/' + module.wrapperName() + '.ngc',
            module.moduleDependency['VERILOG'] + moduleList.getAllDependencies('VERILOG_STUB')  + module.moduleDependency['XST'] ,
            [ SCons.Script.Delete(moduleList.compileDirectory + '/' + module.wrapperName() + '.srp'),
              SCons.Script.Delete(moduleList.compileDirectory + '/' + module.wrapperName() + '_xst.xrpt'),
              'xst -intstyle silent -ifn config/' + module.wrapperName() + '.modified.xst -ofn ' + moduleList.compileDirectory + '/' + module.wrapperName() + '.srp',
              '@echo xst ' + moduleList.compileDirectory + ' build complete.' ])

        module.moduleDependency['SYNTHESIS'] = [w]
        SCons.Script.Clean(w,  moduleList.compileDirectory + '/' + module.wrapperName() + '.srp')
    

    #patch top verilog
    os.system('$BLUESPECDIR/lib/bin/basicinout ' + moduleList.topModule.buildPath + '/' + moduleList.topModule.wrapperName() + '.v');     

    topSRP = moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.srp'

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.ngc',
        moduleList.topModule.moduleDependency['VERILOG'] +  moduleList.getAllDependencies('VERILOG_STUB') + moduleList.topModule.moduleDependency['XST'],
        [ SCons.Script.Delete(topSRP),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName + '_xst.xrpt'),
          'xst -intstyle silent -ifn config/' + moduleList.topModule.wrapperName() + '.xst -ofn ' + topSRP,
          '@echo xst ' + moduleList.apmName + ' build complete.' ])    

    moduleList.topModule.moduleDependency['SYNTHESIS'] = [top_netlist]
    SCons.Script.Clean(top_netlist, topSRP)
