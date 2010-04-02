# -*-Python-*-
import ProjectDependency 

class Module(ProjectDependency.ProjectDependency):

  def dump(self):
    print "Module: " + self.name + "\n"
    print "\tBuildPath: " + self.buildPath + "\n"
    ProjectDependency.ProjectDependency.dump(self);

  
  def __init__(self, name, buildPath, parent, childArray):
    self.name = name
    self.buildPath = buildPath
    self.parent = parent
    self.childArray = childArray
    ProjectDependency.ProjectDependency.__init__(self)

  def wrapperName(self):
    return 'mk_' + self.name + '_Wrapper'
                              
