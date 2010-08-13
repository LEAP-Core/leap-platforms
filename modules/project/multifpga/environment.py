from connection import *
from platform import *

# Import pygraph We'll need it at some point
import pygraph

class Environment(object):

    def __init__(self,platformList):
        self.platforms = {}
        for platform in platformList:
            self.addPlatform(platform)
        self.graphize()


    def addPlatform(self,platform):
        self.platforms[platform.name] = platform;

    def getPlatform(self,name):
        return self.platforms[name]

    # build a graph. This will make life easier
    # graph legalization consists of ensuring that if a platform claims to 
    # be connected to another platform, that platform also claims that they
    # are connected.  This is not the same a bi-directional connection, 
    # however. It serves to make sure that a directional connection has 
    # source  and sink.
    def graphize(self):
        self.graph = pygraph.digraph();

        # first, we must add all the nodes. Only then can we add all the edges
        for platform in self.platforms:
            self.graph.add_nodes([platform])

        for platform in self.platforms:
            sinks = self.platforms[platform].getSinks()
            sources = self.platforms[platform].getSources()
            for sink in sinks:
                # search for paired source - a specification is illegal if 
                # sink/source pairing is not made
                error = 0
                if(sinks[sink].endpointName in self.platforms):
                    if(platform in (self.platforms[sinks[sink].endpointName]).sources):
                        # we have a legal connection
                        
                        self.graph.add_edge(platform,sinks[sink].endpointName)
                        #fill in the source with the sink and the sink with the source
                    else:
                        error = 1
                else:
                    error = 1

                if(error == 1):
                    print 'Illegal graph: ' + sinks[sink].endpointName + ' and ' + platform + ' improperly connected'
                    raise SyntaxError(sinks[sink].endpointName + ' and ' + platform + ' improperly connected')

                # although we've already added a edge for the legal connections, we need to check the reverse
                # in case some source lacks a sink
            for source in sources:
                error = 0
                if(sources[source].endpointName in self.platforms):
                    if(platform in (self.platforms[sources[source].endpointName]).sinks):
                        a = 0 # make python happy....
                        
                    else:
                        error = 1
                else:
                    error = 1

                if(error == 1):
                    print 'Illegal graph: ' + sources[source].endpointName + ' and ' + platform + ' improperly connected'
                    raise SyntaxError(sources[source].endpointName + ' and ' + platform + ' improperly connected')

    # finds/returns the link to use on a path hop from 
    def getPathLength(self, source, sink):
        paths = pygraph.algorithms.minmax.shortest_path(self.graph,source)
        if(sink in paths[1]):           
            return paths[1][sink]
        else:
            return 0

    #It would be worth considering how to handle the key error
    def getPathHop(self, source, sink):
        paths = pygraph.algorithms.minmax.shortest_path(self.graph,source)
        hop = sink
        lastNode = sink 
        while paths[0][hop] != source:
           
            hop = paths[0][hop]
        return hop
        
    # returns the source string for a particular path.  This is currently the min path  
    def getPhysicalSource(self,platform,source):
        return self.platforms[platform].sources[source].physicalName

    def getPhysicalSink(self,platform,sink):
        
        return self.platforms[platform].sinks[sink].physicalName

    
    #build up a keyed dictionary of dictionaries of the single hops to next 
    #nodes nodes without a next are unlisted
    #notice that we generate a listing of all reachable nodes, 
    #not just those that we need.  bluespec will choose the ones that 
    #we need.  We use the memoized connection pointers to build the incoming 
    #list 
    def buildTransitTables(self):
        transitTablesOutgoing = {}
        transitTablesIncoming = {}
        for platformName in self.platforms:
            transitTablesOutgoing[platformName] = {}
            transitTablesIncoming[platformName] = {}

        for platformName in self.platforms:
            platform = self.platforms[platformName]

            for target in self.platforms:
                # check for a connection
                
                if(self.getPathLength(platformName, target) > 0):
                    hop = self.getPathHop(platformName, target)
                    # pygraph returns something odd for paths of length one
                    
                    
                    transitTablesOutgoing[platformName][target] = self.getPhysicalSink(platformName,hop)
                    # also fill in our sink at the same time
                    transitTablesIncoming[hop][platformName] = self.getPhysicalSource(hop,platformName)
                    
        return (transitTablesOutgoing,transitTablesIncoming)

    def __repr__(self):
        platformRepr = ''
        for platform in self.platforms:
            platformRepr = platformRepr + platform.__repr__()
        return platformRepr


