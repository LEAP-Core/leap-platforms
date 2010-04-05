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


  def __init__(self, env, arguments):
      # do a pattern match on the synth boundary paths, which we need to build
      # the module structures
    print "constructing moduleList\n"
    self.env = env
    self.arguments = arguments
    self.compileDirectory = env['DEFS']['TMP_XILINX_DIR']
    self.givenVs = Utils.clean_split(env['DEFS']['GIVEN_VS'], sep = ' ') +  Utils.clean_split(env['DEFS']['GEN_VS'], sep = ' ') 
    self.givenSDCs = Utils.clean_split(env['DEFS']['GIVEN_SDCS'], sep = ' ')
    self.apmName = env['DEFS']['APM_NAME']
    self.moduleList = []
    self.synthBoundaries = env['DEFS']['SYNTH_BOUNDARIES']
    self.wrapper_v = env.SConscript([env['DEFS']['ROOT_DIR_HW_MODEL'] + '/SConscript'])

    if env['DEFS']['GIVEN_CS'] != '':
      SW_EXE_OR_TARGET = env['DEFS']['ROOT_DIR_SW'] + '/obj/' + self.apmName + '_sw.exe'
      SW_EXE = [SW_EXE_OR_TARGET]
    else:
      SW_EXE_OR_TARGET = '$TARGET'
      SW_EXE = []
    self.swExeOrTarget = SW_EXE_OR_TARGET
    self.swExe = SW_EXE

    if len(env['DEFS']['GIVEN_ELFS']) != 0:
      elf = ' -bd ' + str.join(' -bd ',Utils.clean_split(env['DEFS']['GIVEN_ELFS'], sep = ' '))
    else:
      elf = ''
    self.elf = elf

    #
    # Use a cached post par ncd to guide map and par?  This is off by default since
    # the smart guide option can make place & route fail when it otherwise would have
    # worked.  It doesn't always improve run time, either.  To turn on smart guide
    # either define the environment variable USE_SMARTGUIDE or set
    # USE_SMARTGUIDE on the scons command line to a non-zero value.
    #
    self.smartguide_cache_dir = env['DEFS']['WORKSPACE_ROOT'] + '/var/xilinx_ncd'
    self.smartguide_cache_file = self.apmName + '_par.ncd'
    if not os.path.isdir(self.smartguide_cache_dir):
      os.mkdir(self.smartguide_cache_dir)
        
    if ((int(self.arguments.get('USE_SMARTGUIDE', 0)) or self.env['ENV'].has_key('USE_SMARTGUIDE')) and
        (FindFile(self.apmName + '_par.ncd', [self.smartguide_cache_dir]) != None)):
      self.smartguide = ' -smartguide ' +  self.smartguide_cache_dir + '/' + self.smartguide_cache_file
    else:
      self.smartguide = ''

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
    self.topModule.moduleDependency['VERILOG'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper.v'] + self.givenVs + Utils.get_bluespec_verilog(env)

    self.topModule.moduleDependency['VERILOG_STUB'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper_stub.v'] 
    # deal with other modules
    for module in self.moduleList:
      module.moduleDependency['XST'] = ['config/' + module.wrapperName() + '.xst']
      module.moduleDependency['VERILOG'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper.v'] + self.givenVs + Utils.get_bluespec_verilog(env)
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
