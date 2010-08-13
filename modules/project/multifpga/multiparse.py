import sys
import ply.yacc as yacc
from connection import *
from environment import *
from platform import *

def p_environment(p):
    """
    environment :
    environment : platform_list
    """
   
    if len(p) == 1:
        p[0] = Environment([])
    else:
        p[0] = Environment(p[1])    

def p_platform_list(p):
    """
    platform_list :
    platform_list : PLATFORM NAME SEMICOLON connection_list ENDPLATFORM platform_list
    """
    if len(p) == 1:
        p[0] = []  # end of list - may want to do stuff here.
    else:
        p[0] = [Platform(p[2],p[4])] + p[6] 
        
def p_connection_list(p):
    """
    connection_list :
    connection_list : NAME RARROW path SEMICOLON connection_list
    connection_list : NAME LARROW path SEMICOLON connection_list
    """     
    if len(p) == 1:
        p[0] = []
    else:
        if(p[2] == '<-'):
            p[0] = [Connection(Connection.sink,p[1],p[3])] + p[5]
        else:
            p[0] = [Connection(Connection.source,p[1],p[3])] + p[5]

def p_path(p):
    """
    path : NAME
    path : NAME PERIOD path
    """     
    if len(p) == 2:
        p[0] = p[1]
    else:
        p[0] = p[1] + '.' + p[3]
