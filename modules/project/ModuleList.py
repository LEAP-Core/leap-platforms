# -*-Python-*-

import os
import string
import Module

class ModuleList:
  
  moduleList = []
  compileDirectory = ""
  givenVs = []
  synthTop = ""
  topVerilog = ""
  xstOptions = ""
  env = ""  

  def dump(self):
    print "compileDirectory: " + self.compileDirectory + "\n"
    print "givenVs: "    
    for v in self.givenVs:
      print v + " "
    print "\n" 
    print "synthTop: " + self.synthTop + "\n"
    print "topVerilog: " + self.topVerilog + "\n"


  def __init__(self, synthBoundaries, compileDirectoryIn, givenVsIn, synthTopIn, topVerilogIn, env):
      # do a pattern match on the synth boundary paths, which we need to build
      # the module structures
    print "synthTop In: " + synthTopIn + "\n";
    print "topVerilogIn: " + topVerilogIn + "\n";
    print "compileDirectoryIn: " + compileDirectoryIn + "\n";
    self.compileDirectory = compileDirectoryIn
    self.givenVs = givenVsIn
    self.synthTop = synthTopIn
    self.topVerilog = topVerilogIn
    self.env = env
    for wrapper in synthBoundaries:
      self.moduleList.append(Module.Module(wrapper))
    
    
