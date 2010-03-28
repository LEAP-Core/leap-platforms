# -*-Python-*-

class ProjectDependency:

  topDependency = "" # this should be a combination of the module deps, but let's not assume that for now.
  moduleDependency = []

  def dump(self):
    print "Module Deps: "     
    for dep in self.moduleDependency:
      print dep + " "
    print "\n" 
    print "Top Dep: " + self.topDependency + "\n"

  def __init__(self):
    # don't do anything here
    # but this is needed to make the inheritance happy 
    self.moduleDependency = []

