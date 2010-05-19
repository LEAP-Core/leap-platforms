import os
import re
import SCons.Script  
from model import  *
from synthesis_tool import  *
from post_synthesis_tool import *

class Build(ProjectDependency):
  def __init__(self, moduleList):
    Synthesize(moduleList)

    print "finish configuring Synthesize \n"
  

    PostSynthesize(moduleList)

    print "finish configuring PostSynthesize \n"


