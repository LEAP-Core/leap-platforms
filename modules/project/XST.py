import os

from SCons.Script import *
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class Synthesize(ProjectDependency):
  def __init__(self, moduleList):
    for module in moduleList.moduleList:    
        w = moduleList.env.Command(
            moduleList.compileDirectory + '/' + module.synthTop + '.ngc',
            moduleList.givenVs + ['config/' + module.synthTop + '.xst'],
            [ Delete(moduleList.compileDirectory + '/' + module.synthTop + '.srp'),
              Delete(moduleList.compileDirectory + '/' + module.synthTop + '_xst.xrpt'),
              'xst -intstyle silent -ifn config/' + module.synthTop + '.xst -ofn ' + moduleList.compileDirectory + '/' + module.synthTop + '.srp',
              '@echo xst ' + moduleList.compileDirectory + ' build complete.' ])

        module.ngc = [moduleList.compileDirectory + '/' + module.synthTop  + '.ngc']
        module.synthDependency = w 

        self.moduleDependency += w
        Clean(w,  moduleList.compileDirectory + '/' + module.synthTop + '.srp')
    
    topSRP = moduleList.compileDirectory + '/' + moduleList.synthTop + '.srp'

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.synthTop + '.ngc',
        moduleList.topVerilog + moduleList.givenVs + ['config/' + moduleList.synthTop + '.xst'],
        [ Delete(topSRP),
          Delete(moduleList.compileDirectory + '/' + moduleList.synthTop + '_xst.xrpt'),
          'xst -intstyle silent -ifn config/' + moduleList.synthTop + '.xst -ofn ' + topSRP,
          '@echo xst ' + moduleList.synthTop + ' build complete.' ])    

    self.topDependency = top_netlist

    Clean(top_netlist, topSRP)
