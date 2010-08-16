import os
import re
import SCons.Script  
from iface_tool import *
from bsv_tool import *
from bluesim_tool import *
from software_tool import *
from model import  *

class Build(ProjectDependency):
  def __init__(self, moduleList):

    #build interface first 
    Iface(moduleList)
    BSV(moduleList)
    Software(moduleList)
    Verilog(moduleList)
    #Return something useful to the top level
