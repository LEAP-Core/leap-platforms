import os
import SCons.Script
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class Synthesize(ProjectDependency):
  def __init__(self, moduleList):
    for module in moduleList.moduleList:    
        w = moduleList.env.Command(
            moduleList.compileDirectory + '/' + module.synthTop + '.ngc',
            moduleList.givenVs + ['config/' + module.synthTop + '.xst'],
            [ SCons.Script.Delete(moduleList.compileDirectory + '/' + module.synthTop + '.srp'),
              SCons.Script.Delete(moduleList.compileDirectory + '/' + module.synthTop + '_xst.xrpt'),
              'xst -intstyle silent -ifn config/' + module.synthTop + '.xst -ofn ' + moduleList.compileDirectory + '/' + module.synthTop + '.srp',
              '@echo xst ' + moduleList.compileDirectory + ' build complete.' ])

        module.ngc = [moduleList.compileDirectory + '/' + module.synthTop  + '.ngc']
        module.synthDependency = w 

        self.moduleDependency += w
        SCons.Script.Clean(w,  moduleList.compileDirectory + '/' + module.synthTop + '.srp')
    
    topSRP = moduleList.compileDirectory + '/' + moduleList.synthTop + '.srp'

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.synthTop + '.ngc',
        moduleList.topVerilog + moduleList.givenVs + ['config/' + moduleList.apmName + '.xst'],
        [ SCons.Script.Delete(topSRP),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apnName + '_xst.xrpt'),
          'xst -intstyle silent -ifn config/' + moduleList.apmName + '.xst -ofn ' + topSRP,
          '@echo xst ' + moduleList.apmName + ' build complete.' ])    

    self.topDependency = top_netlist

    SCons.Script.Clean(top_netlist, topSRP)
