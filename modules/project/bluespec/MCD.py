import os
import sys
import re
import SCons.Script
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path



class MCD():

  # apparently for functional-style python we can only pass a reference
  # to a function so, all args must be a part of the object.
  # we also apparently get to see target, source, and env in the build
  def mcdCommand(self, target, source, env):
    # Open file, into which we will dump the magic TIG strings 
  
    mcdUCF = open(self.mcdUCFFile,'w')
    foundDomainCrossing = 0

    # handle the rest of the tree
    for logfile in self.logfiles:
        print('Trying to open '+logfile+'\n')
        compileLog = open(logfile,'r')
        # look for the domain crossing string 
        searchResult = re.search(r'CrossDomain',compileLog.read())
        if(searchResult):  
          print ('Found domain crossing')
          foundDomainCrossing = 1
    
    # add the ucf to the global context for downstream processing
    if(foundDomainCrossing): 
      mcdUCF.write('\n#These take care of the MCD soft connection\n')
      mcdUCF.write('NET "*_domainFIFO*_dD_OUT[*]" TIG;\n')
      mcdUCF.write('NET "*_domainFIFO*/dGDeqPtr[*]" TIG;\n')
      mcdUCF.write('NET "*_domainFIFO*/dGDeqPtr1[*]" TIG;\n')
      mcdUCF.write('NET "*_domainFIFO*/sGEnqPtr[*]" TIG;\n')
      mcdUCF.write('NET "*_domainFIFO*/sGEnqPtr1[*]" TIG;\n')
      
    mcdUCF.close();
    

  def __init__(self, moduleList):
   
    # concat the modules and the top
    allModules = [moduleList.topModule] + moduleList.synthBoundaries()
    self.mcdUCFFile = 'config/' + moduleList.topModule.wrapperName() + '.mcd.ucf' 

    # determine what the logfile paths will be
    self.logfiles = []
    for module in allModules:
        self.logfiles.append('hw/' + module.buildPath + '/.bsc/' + module.name + '_Wrapper.log')
    # although we examine the log files, we depend on the 
    # verilogs which are produced in conjunction
    if('UCF' in moduleList.topModule.moduleDependency):
        mcd_ucf = moduleList.env.Command(
        self.mcdUCFFile,
        moduleList.topModule.moduleDependency['VERILOG'],
        self.mcdCommand)
        moduleList.topModule.moduleDependency['UCF'] = moduleList.topModule.moduleDependency['UCF'] + mcd_ucf
        SCons.Script.Clean(moduleList.topModule.moduleDependency['UCF'] , self.mcdUCFFile)


