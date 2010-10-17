# -*-Python-*-

import os
import sys
import string
import pygraph
from pygraph.classes.digraph import digraph
import pygraph.algorithms.sorting
import Module
import Utils

def checkSynth(module):
  return module.isSynthBoundary


class ModuleList:
  
  def dump(self):
    print "compileDirectory: " + self.compileDirectory + "\n"
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
    self.buildDirectory = env['DEFS']['BUILD_DIR']
    self.compileDirectory = env['DEFS']['TMP_XILINX_DIR']
    givenVerilogs = Utils.clean_split(env['DEFS']['GIVEN_VERILOGS'], sep = ' ') 
    givenNGCs = Utils.clean_split(env['DEFS']['GIVEN_NGCS'], sep = ' ') 
    givenVHDs = Utils.clean_split(env['DEFS']['GIVEN_VHDS'], sep = ' ') 
    self.apmName = env['DEFS']['APM_NAME']
    self.moduleList = []
    synthBoundaries = env['DEFS']['SYNTH_BOUNDARIES']
    #We should be invoking this elsewhere?
    #self.wrapper_v = env.SConscript([env['DEFS']['ROOT_DIR_HW_MODEL'] + '/SConscript'])

    # this really doesn't belong here. 
    if env['DEFS']['GIVEN_CS'] != '':
      SW_EXE_OR_TARGET = env['DEFS']['ROOT_DIR_SW'] + '/obj/' + self.apmName + '_sw.exe'
      SW_EXE = [SW_EXE_OR_TARGET]
    else:
      SW_EXE_OR_TARGET = '$TARGET'
      SW_EXE = []
    self.swExeOrTarget = SW_EXE_OR_TARGET
    self.swExe = SW_EXE

    self.swIncDir = Utils.clean_split(env['DEFS']['SW_INC_DIRS'], sep = ' ')
    self.swLibs = Utils.clean_split(env['DEFS']['SW_LIBS'], sep = ' ')
    self.m5BuildDir = env['DEFS']['M5_BUILD_DIR'] 
    self.rootDirSw = env['DEFS']['ROOT_DIR_SW_MODEL']
    self.rootDirInc = env['DEFS']['ROOT_DIR_SW_INC']


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

    # deal with other modules

    for module in self.moduleList:
      module.moduleDependency['VERILOG'] = givenVerilogs
      module.moduleDependency['BA'] = []
      module.moduleDependency['VERILOG_STUB'] = []
      module.moduleDependency['NGC'] = givenNGCs
      module.moduleDependency['VHD'] = givenVHDs

    for module in synthBoundaries:
      # each module has a generated bsv
      # check to see if this is the top module (has no parent)
      if(module.parent == ''): 
        self.topModule = module
      else:
        self.moduleList.append(module)
      #This should be done in xst process 
      module.moduleDependency['XST'] = ['config/' + module.wrapperName() + '.xst']
      module.moduleDependency['VERILOG'] = ['hw/' + module.buildPath + '/.bsc/mk_' + module.name + '_Wrapper.v'] + givenVerilogs + Utils.get_bluespec_verilog(env)
      module.moduleDependency['BA'] = []


    #Notice that we call get_bluespec_verilog here this will
    #eventually called by the BLUESPEC build rule
    self.topModule.moduleDependency['XST'] = ['config/' + self.topModule.wrapperName() + '.xst']
    self.topModule.moduleDependency['VERILOG'] = ['hw/' + self.topModule.buildPath + '/.bsc/mk_' + self.topModule.name + '_Wrapper.v'] + givenVerilogs + Utils.get_bluespec_verilog(env)
    self.topModule.moduleDependency['VERILOG_STUB'] = []
    self.topModule.moduleDependency['NGC'] = givenNGCs
    self.topModule.moduleDependency['VHD'] = givenVHDs
    self.topModule.moduleDependency['UCF'] =  Utils.clean_split(self.env['DEFS']['GIVEN_UCFS'], sep = ' ')
    self.topModule.moduleDependency['XCF'] =  Utils.clean_split(self.env['DEFS']['GIVEN_XCFS'], sep = ' ')
    self.topModule.moduleDependency['SDC'] = Utils.clean_split(env['DEFS']['GIVEN_SDCS'], sep = ' ')
    self.topModule.moduleDependency['BA'] = []

    self.topDependency=[]
    self.graphize()
    self.graphizeSynth()
    
  def getAllDependencies(self, key):
    # we must check to see if the dependencies actually exist.
    allDeps = []
    if(self.topModule.moduleDependency.has_key(key)):
      allDeps = self.topModule.moduleDependency[key]
    for module in self.moduleList:
      if(module.moduleDependency.has_key(key)):
        allDeps += module.moduleDependency[key]

    if(len(allDeps) == 0):
      sys.stderr.write("Warning: no dependencies were found")

    return allDeps

  # walk down the source tree from the given module to its leaves, 
  # which are either true leaves or underlying synth boundaries. 
  def getSynthBoundaryDependencies(self, module, key):
    # we must check to see if the dependencies actually exist.
    allDesc = self.getSynthBoundaryDescendents(module)

    # grab my deps
    allDeps = []
    for desc in allDesc:
      if(desc.moduleDependency.has_key(key)):
        allDeps += desc.moduleDependency[key]

    if(len(allDeps) == 0):
      sys.stderr.write("Warning: no dependencies were found")
    
    return allDeps

  # returns the synthesis children of a given module.
  def getSynthBoundaryChildren(self, module):
    return self.graphSynth.neighbors(module)    

  # get everyone below this synth boundary
  # this is a recursive call
  def getSynthBoundaryDescendents(self, module):
    return self.getSynthBoundaryDescendentsHelper(True, module)
           
  ### FIX ME
  def getSynthBoundaryDescendentsHelper(self, ignoreSynth, module): 
    allDeps = []

    if(module.isSynthBoundary and not ignoreSynth):
      return allDeps

    # else return me
    allDeps = [module]

    neighbors = self.graph.neighbors(module)
    for neighbor in neighbors:
      allDeps += self.getSynthBoundaryDescendentsHelper(False,neighbor) 

    return allDeps

  # We carry around two representations of the source tree.  One is the 
  # original representation of the module tree, which will be helpful in 
  # gathering the sources of various modules.  The second is a tree of synthesis
  # boundaries, helpful, obviously, in actually constructing things.  
  
  def graphize(self):
    self.graph = digraph()
    modules = [self.topModule] + self.moduleList
    # first, we must add all the nodes. Only then can we add all the edges
    self.graph.add_nodes(modules)

    # here we have a strictly directed graph, so we need only insert directed edges
    for module in modules:
      def checkParent(child):
        if module.name == child.parent:
          return True
        else:
          return False

      children = filter(checkParent, modules)
      for child in children:
        self.graph.add_edge((module,child)) 
  # and this concludes the graph build


  # returns a dependency based topological sort of the source tree 
  def topologicalOrder(self):
       return pygraph.algorithms.sorting.topological_sorting(self.graph)

  def graphizeSynth(self):
    self.graphSynth = digraph()
    modulesUnfiltered = [self.topModule] + self.moduleList
    # first, we must add all the nodes. Only then can we add all the edges
    # filter by synthesis boundaries
    modules = filter(checkSynth, modulesUnfiltered)
    self.graphSynth.add_nodes(modules)

    # here we have a strictly directed graph, so we need only insert directed edges
    for module in modules:
      def checkParent(child):
        if module.name == child.synthParent:
          return True
        else:
          return False

      children = filter(checkParent, modules)
      for child in children:
        self.graphSynth.add_edge((module,child)) 
  # and this concludes the graph build


  # returns a dependency based topological sort of the source tree 
  def topologicalOrderSynth(self):
    return pygraph.algorithms.sorting.topological_sorting(self.graphSynth)

  def synthBoundaries(self):
    return filter(checkSynth, self.moduleList)
