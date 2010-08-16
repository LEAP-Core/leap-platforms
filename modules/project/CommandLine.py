# some common tools for handling frequently occuring 
# command flags like Debug

import os
import sys
import string
import Utils


##
## DEBUG or OPT build?  User can override the workspace default rule by
## specifying either OPT=1 or DEBUG=1 on the scons command line.
##
def getDebug(moduleList):
    if (int(moduleList.arguments.get('OPT', 0))):
        return 0
    elif (int(moduleList.arguments.get('DEBUG', 0))):
        return 1
    else:
        return int(Utils.awb_resolver('-config=debug'))


##
## Enable tracing (software side debugging)?  Always enabled in debug mode.
##
def getTrace(moduleList):
    TRACE = int(moduleList.arguments.get('TRACE', 0))
    if (getDebug(moduleList)):
        TRACE = 1
    return TRACE
    

def getEvents(moduleList):
    enable_events = int(moduleList.arguments.get('EVENTS', -1))
    if (enable_events == -1):
        enable_events = int(Utils.awb_resolver('-config=events'))
    return enable_events
