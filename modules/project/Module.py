# -*-Python-*-
import ProjectDependency 

class Module(ProjectDependency.ProjectDependency):

  def dump(self):
    print "Module: " + self.name + "\n"
    print "\tBuildPath: " + self.buildPath + "\n"
    ProjectDependency.ProjectDependency.dump(self);

  
  def __init__(self, name, isSynthBoundary, buildPath, computePlatform, parent, childArray, synthParent, synthChildArray, sources):
    self.name = name
    self.buildPath = buildPath
    self.parent = parent
    self.childArray = childArray
    self.isSynthBoundary = isSynthBoundary
    self.synthParent = synthParent
    self.synthChildArray = synthChildArray
    self.computePlatform = computePlatform
    ProjectDependency.ProjectDependency.__init__(self)
    # grab the deps from source lists. 
    # we don't insert the special generated files that awb 
    # seems to generate.  these should be inserted by
    # downstream tools 
    self.moduleDependency = sources 
          

  def wrapperName(self):
    return 'mk_' + self.name + '_Wrapper'
                              
