# -*-Python-*-

import os
import string
import Module
import Utils

class ModuleList:
  
  def dump(self):
    print "compileDirectory: " + self.compileDirectory + "\n"
    print "givenVs: "    
    for v in self.givenVs:
      print v + " "
    print "\n" 
    print "givenSDCs: "    
    for sdc in self.givenSDCs:
      print sdc + " "
    print "\n "
    print "Modules: "
    self.topModule.dump()  
    for module in self.moduleList:
      module.dump()
    print "\n "
    print "apmName: " + self.apmName + "\n"


  def __init__(self, synthBoundaries, compileDirectory, givenVs, givenSDCs, env, apmName):
      # do a pattern match on the synth boundary paths, which we need to build
      # the module structures
    print "constructing moduleList\n"
    self.compileDirectory = compileDirectory
    self.givenVs = givenVs
    self.givenSDCs = givenSDCs
    self.apmName = apmName
    self.env = env
    self.moduleList = []
    for module in synthBoundaries:
      # check to see if this is the top module (has no parent)
      module.dump()
      if(module.parent == ''): 
        self.topModule = module
      else:
        print "adding " + module.name + " to module list" 
        self.moduleList.append(module)
    
  #for now, this will fill in the default   
  def defaultVerilog(self, wrapper_v):
    self.topModule.moduleDependency['XST'] = ['config/' + self.topModule.wrapperName() + '.xst']
    self.topModule.moduleDependency['VERILOG'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper.v'] + wrapper_v + Utils.clean_split(self.env['DEFS']['GIVEN_VS'], sep = ' ')
    self.topModule.moduleDependency['VERILOG_STUB'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper_stub.v'] 
    # deal with other modules
    for module in self.moduleList:
      module.moduleDependency['XST'] = ['config/' + module.wrapperName() + '.xst']
      module.moduleDependency['VERILOG'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper.v'] + wrapper_v + Utils.clean_split(self.env['DEFS']['GIVEN_VS'], sep = ' ')
      module.moduleDependency['VERILOG_STUB'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper_stub.v']     

 
  def getAllDependencies(self, key):
    allDeps = self.topModule.moduleDependency[key]
    for module in self.moduleList:
      allDeps += module.moduleDependency[key]

    return allDeps
