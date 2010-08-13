from connection import *

class Platform(object):

    def getSinks(self):
        return self.sinks

    def getSources(self):
        return self.sources

    def insertSink(self,target,via):
        self.sinks[target] = via

    def insertSource(self,target,via):
        self.sources[target] = via
    
    def __init__(self, name, connectionList):
        self.name = name
        self.sources = {}
        self.sinks = {}
        for connection in connectionList:
            if(connection.direction == Connection.source):
                self.insertSource(connection.endpointName,connection)
            else:
                self.insertSink(connection.endpointName,connection)

    def __repr__(self):
       sourceRepr = ''
       for source in self.sources:
           sourceRepr = sourceRepr + self.sources[source].__repr__() + '\n'
           
       sinkRepr = ''
       for sink in self.sinks:
           sinkRepr = sinkRepr + self.sinks[sink].__repr__() + '\n'
           
       return 'Platform ' + self.name + '\n Sources: \n' + sourceRepr + '\n Sinks: \n' + sinkRepr
