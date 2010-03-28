# -*-Python-*-

class Module:

  synthTop = ""
  synthDependency = ""
  ngc = ""

  def dump(self):
    print "wrapperIn: " + self.synthTop + "\n"
    print "ngc: " + self.ngc + "\n"

  def __init__(self, synthTopIn):
    synthTop = synthTopIn
