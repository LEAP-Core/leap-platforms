# -*-Python-*-

import os
import string
import Module

class ModuleList:
  
  moduleList = []
  compileDirectory = ""
  givenVs = []
  givenSDCs = []
  synthTop = ""
  topVerilog = ""
  xstOptions = ""
  env = ""  
  apmName = ""   
  
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
    print "apmName: " + self.apmName + "\n"
    print "synthTop: " + self.synthTop + "\n"
    print "topVerilog: " + self.topVerilog + "\n"


  def __init__(self, synthBoundaries, compileDirectory, givenVs, givenSDCs, synthTop, topVerilog, env, apmNameIn):
      # do a pattern match on the synth boundary paths, which we need to build
      # the module structures
    print "synthTop In: " + synthTop + "\n";
    print "topVerilogIn: " + topVerilog + "\n";
    print "compileDirectoryIn: " + compileDirectory + "\n";
    self.compileDirectory = compileDirectory
    self.givenVs = givenVs
    self.givenSDCs = givenSDCs
    self.synthTop = synthTop
    self.topVerilog = topVerilog
    self.env = env
    self.apmName = apmNameIn
    for wrapper in synthBoundaries:
      self.moduleList.append(Module.Module(wrapper))
    
    
