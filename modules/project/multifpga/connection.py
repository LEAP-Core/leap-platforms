class Connection(object):

    source = 1
    sink = 0

    def __init__(self, direction, endpointName, physicalName):
        self.endpointName = endpointName
        self.direction = direction
        self.physicalName = physicalName
        self.connectionPair = object() # put a junk object in here we'll fill it in later

    def __repr__(self):
        if(self.direction == Connection.source):
            return 'CONNECTION\n' + self.endpointName + ' input from '  + self.physicalName
        else:
            return 'CONNECTION\n' + self.endpointName + ' output to '  + self.physicalName

