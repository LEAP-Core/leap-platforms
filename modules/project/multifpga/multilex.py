# platform P;
#   Q -> qinconnect;
#   R -> rinconnect;
#   R <- routconnect;
# endplatform

reserved = {
    'platform': 'PLATFORM',
    'endplatform': 'ENDPLATFORM',
    'unknown': 'UNKOWN',
    }

tokens = [ 'RARROW', 'LARROW', 'SEMICOLON',
           'NAME', 'PERIOD',
         ] + list(reserved.values())


t_RARROW = r'->'
t_LARROW = r'<-'
t_PERIOD = r'\.'
t_SEMICOLON = r';'
t_PLATFORM = r'platform'
t_ENDPLATFORM = r'endplatform'
t_ENDPLATFORM = r'unknown'

def t_NAME(t):
    r'[a-zA-Z_][a-zA-Z0-9_]*'
    t.type = reserved.get(t.value,'NAME')
    return t

t_ignore = " \t\r" #white space requirements are evil

def t_newline(t):
    r'\n+'
    t.lexer.lineno += t.value.count("\n") 

def t_error(t):
    print 'Error at ' + str(t.lexer.lineno) +  ': Illegal character ' + t.value[0]
    t.lexer.skip(1) 

