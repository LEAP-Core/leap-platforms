import os
import re
import SCons.Script  
from model import  *
from iface_tool import *
from bsv_tool import *
from software_tool import *
from synthesis_tool import  *
from post_synthesis_tool import *
from mcd_tool import *

class Build(ProjectDependency):
  def __init__(self, moduleList):
    Iface(moduleList)
    BSV(moduleList)
    Software(moduleList)
    MCD(moduleList)
    #moduleList.dump()
    Synthesize(moduleList)
    #moduleList.dump()
    print "finish configuring Synthesize \n"
    PostSynthesize(moduleList)
    print "finish configuring PostSynthesize \n"


