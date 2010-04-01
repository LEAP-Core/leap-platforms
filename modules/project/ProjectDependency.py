# -*-Python-*-

class ProjectDependency:

  def dump(self):
    print "Deps: \n"     
    for key in self.moduleDependency:
      print "\t" + key + ": "
      #need to case on types here, I guess
      for dep in self.moduleDependency[key]:
        print dep
        print "\n"
      print "\n" 

  def __init__(self):
    # don't do anything here
    # but this is needed to make the inheritance happy 
    self.moduleDependency = {}

