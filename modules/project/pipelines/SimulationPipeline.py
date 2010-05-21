import os
import re
import SCons.Script  
from model import  *

class Build(ProjectDependency):
  def __init__(self, moduleList):
    # Nothing to do here until the Bluespec build is cooked out of the 
    # top level
    moduleList.topModule.moduleDependency['LOADER'] = ''
