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
    print "\n"
    print "apmName: " + self.apmName + "\n"


  def __init__(self, env):
      # do a pattern match on the synth boundary paths, which we need to build
      # the module structures
    print "constructing moduleList\n"
    self.compileDirectory = env['DEFS']['TMP_XILINX_DIR']
    self.givenVs = Utils.clean_split(env['DEFS']['GIVEN_VS'], sep = ' ')
    self.givenSDCs = Utils.clean_split(env['DEFS']['GIVEN_SDCS'], sep = ' ')
    self.apmName = env['DEFS']['APM_NAME']
    self.env = env
    self.moduleList = []
    self.synthBoundaries = env['DEFS']['SYNTH_BOUNDARIES']
    self.wrapper_v = env.SConscript([env['DEFS']['ROOT_DIR_HW_MODEL'] + '/SConscript'])
    for module in self.synthBoundaries:
      # check to see if this is the top module (has no parent)
      module.dump()
      if(module.parent == ''): 
        self.topModule = module
      else:
        print "adding " + module.name + " to module list" 
        self.moduleList.append(module)

    self.topModule.moduleDependency['XST'] = ['config/' + self.topModule.wrapperName() + '.xst']
    #Notice that we call get_bluespec_verilog here this will eventually called by the BLUESPEC build rule 
    self.topModule.moduleDependency['VERILOG'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper.v'] + self.wrapper_v + self.givenVs + Utils.get_bluespec_verilog(env)

    self.topModule.moduleDependency['VERILOG_STUB'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper_stub.v'] 
    # deal with other modules
    for module in self.moduleList:
      module.moduleDependency['XST'] = ['config/' + module.wrapperName() + '.xst']
      module.moduleDependency['VERILOG'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper.v'] + self.wrapper_v + self.givenVs + Utils.get_bluespec_verilog(env)
      module.moduleDependency['VERILOG_STUB'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper_stub.v']     
    
    
  def getAllDependencies(self, key):
    # we must check to see if the dependencies actually exist.
    allDeps = []
    if(self.topModule.moduleDependency.has_key(key)):
      allDeps = self.topModule.moduleDependency[key]
    for module in self.moduleList:
      if(module.moduleDependency.has_key(key)):
        allDeps += module.moduleDependency[key]

    if(len(allDeps) == 0):
      sys.stderr.write("Warning, no dependencies were found")

    return allDeps
