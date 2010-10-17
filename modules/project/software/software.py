import os
import sys
import re
import SCons.Script
from model import  *

def host_defs():
    hostos = one_line_cmd('uname -s')
    hostmachine = one_line_cmd('uname -m')

    if (hostos == 'FreeBSD'):
        hflags = '-DHOST_FREEBSD'
    else:
        hflags = '-DHOST_LINUX'
        if (hostmachine == 'ia64'):
            hflags += ' -DHOST_LINUX_IA64'
        else:
            hflags += ' -DHOST_LINUX_X86'

    return hflags

# Baking out M5 at some point would be a good idea

class Software():

  def __init__(self, moduleList):

    # set up trace flags
    if (getEvents(moduleList) == 0):       
       cpp_events_flag = ''
    else:
       cpp_events_flag = '-DHASIM_EVENTS_ENABLED'

    if moduleList.swExe != []:
        inc_paths = moduleList.swIncDir
        libs = moduleList.swLibs
        cc_flags = host_defs()
        cc_flags += ' ' + cpp_events_flag
        if (getDebug(moduleList)):
            cc_flags += ' -DASIM_ENABLE_ASSERTIONS'
        if (getTrace(moduleList)):
            cc_flags += ' -DASIM_ENABLE_TRACE'
        cc_flags += ' -DAPM_NAME=\\"' + moduleList.apmName + '\\"'
    
        ##
        ## These will be defined if the m5 simulator is part of the model
        ##
        M5_BUILD_DIR = moduleList.m5BuildDir
        if (M5_BUILD_DIR != ''):
            # m5 needs Python library
            inc_paths += [ os.path.join(sys.exec_prefix, 'include', 'python' + sys.version[:3]) ]
            python_zip = os.path.join(awb_resolver(M5_BUILD_DIR), 'm5py.zip')
    
            cc_flags += ' -DTRACING_ON=1'
            if (moduleList.env['DEFS']['SIMULATED_ISA'] != ''):
                cc_flags += ' -DTHE_ISA=' + moduleList.env['DEFS']['SIMULATED_ISA'] + '_ISA'
    
            if (getDebug(moduleList)):
                cc_flags += ' -DDEBUG'
                # Swap the optimized m5 library for a debugging one
                tmp_libs = []
                for lib in libs:
                    if (os.path.basename(lib) == 'libm5_opt.a'):
                        tmp_libs += [ os.path.join(os.path.dirname(lib), 'libm5_debug.a') ]
                    else:
                        tmp_libs += [ lib ]
                libs = tmp_libs
    
        if (getDebug(moduleList)):
            copt_flags = '-ggdb3 '
        else:
            copt_flags = '-g -O2 '
    
        # CPPPATH defines both gcc include path and dependence path for
        # SCons.  The '#' forces paths to be relative to the root of the build.
        sw_env = moduleList.env.Clone(CCFLAGS = copt_flags + cc_flags,
                           LINKFLAGS = copt_flags,
                           CPPPATH = [ '#/' + moduleList.rootDirInc,
                                       '#/' + moduleList.rootDirSw,
                                       '#/iface/build/include',
                                       '.' ] + inc_paths)
    
        sw_env['DEFS']['CWD_REL'] = sw_env['DEFS']['ROOT_DIR_SW_MODEL']
    
        moduleList.env.Export('sw_env')
        sw_build_dir = sw_env['DEFS']['ROOT_DIR_SW'] + '/obj'
        sw_objects = moduleList.env.SConscript([moduleList.rootDirSw + '/SConscript'],
                                build_dir = sw_build_dir,
                                duplicate = 0)
    
        sw_libpath = [ '.' ]
        sw_link_libs = [ 'pthread', 'dl' ]
    
        sw_link_tgt = moduleList.swExe
    
    
        ##
        ## m5 needs libz, libmysqlclient and Python library
        ##
        if (M5_BUILD_DIR != ''):
            sw_link_libs += [ 'z' ]
    
            if (os.path.exists(os.path.join(sys.exec_prefix, 'lib' , 'libmysqlclient.a'))):
                sw_link_libs += [ 'mysqlclient' ]
            elif (os.path.exists(os.path.join(sys.exec_prefix, 'lib', 'mysql' , 'libmysqlclient.a'))):
                sw_link_libs += [ 'mysqlclient' ]
    
            # m5 needs python
            sw_libpath += [ os.path.join(sys.exec_prefix, 'lib') ]
            sw_link_libs += [ 'python' + sys.version[:3] ]
    
            # m5 links a temporary file then adds Python code
            sw_link_tgt = [ moduleList.swExe[0] + '.no_python' ]
    
    
        ##
        ## Put libs on the list of objects twice as a hack to work around the
        ## inability to specify the order of %library declarations across separate
        ## awb files.  Unix ld only searches libraries in command line order.
        ##
        sw_exe = sw_env.Program(sw_link_tgt, sw_objects + libs + libs, LIBPATH=sw_libpath, LIBS=sw_link_libs)
    
        if (M5_BUILD_DIR != ''):
            ##
            ## Define a simple SCons builder to concatenate files.  Used to append the
            ## Python zip archive to the executable.
            ##
            concat_builder = Builder(action = Action(['cat $SOURCES > $TARGET',
                                                      'chmod +x $TARGET']))
            sw_env.Append(BUILDERS = { 'Concat' : concat_builder })
    
            # Append Python code to the binary
            sw_exe = sw_env.Concat(moduleList.swExe, [ sw_exe, python_zip ])
                                                                                                                                                              
    moduleList.topDependency = moduleList.topDependency + [sw_exe]     
