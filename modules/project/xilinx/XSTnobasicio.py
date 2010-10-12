import os
import sys
import SCons.Script
from model import  *


#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class Synthesize():
  def __init__(self, moduleList):

    # string together the xcf, sort of like the ucf
    # Concatenate UCF files
    if('XCF' in moduleList.topModule.moduleDependency and len(moduleList.topModule.moduleDependency['XCF']) > 0):
      for xcf in  moduleList.topModule.moduleDependency['XCF']:
        print 'xst found xcf: ' + xcf + '\n' 
      xilinx_xcf = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName()+ '.xcf',
        moduleList.topModule.moduleDependency['XCF'],
        'cat $SOURCES > $TARGET')
    else:
      xilinx_xcf = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName()+ '.xcf',
        [],
        'touch $TARGET')

    ## tweak top xst file
    newXSTFile = open('config/' + moduleList.topModule.wrapperName() + '.modified.xst','w')
    oldXSTFile = open('config/' + moduleList.topModule.wrapperName() + '.xst','r')
    newXSTFile.write(oldXSTFile.read());
    newXSTFile.write('-iobuf yes\n');
    newXSTFile.write('-uc ' + moduleList.env['DEFS']['BUILD_DIR'] + '/'+ moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName()+ '.xcf\n');
    newXSTFile.close();
    oldXSTFile.close();


    for module in moduleList.synthBoundaries():    
        # we must tweak the xst files of the internal module list
        # to prevent the insertion of iobuffers
        newXSTFile = open('config/' + module.wrapperName() + '.modified.xst','w')
        oldXSTFile = open('config/' + module.wrapperName() + '.xst','r')
        newXSTFile.write(oldXSTFile.read());
        newXSTFile.write('-iobuf no\n');
        newXSTFile.write('-uc  '+ moduleList.env['DEFS']['BUILD_DIR'] + '/' + moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName()+ '.xcf\n');
        newXSTFile.close();
        oldXSTFile.close();
        print 'For ' + module.name + ' explicit vlog: ' + str(module.moduleDependency['VERILOG'])
        # need to sort these?  SCons complains about it.
        vlogStubs = moduleList.getAllDependencies('VERILOG_STUB')
        vlogStubs.sort()
        vlog = module.moduleDependency['VERILOG']
        vlog.sort()
        w = moduleList.env.Command(
            moduleList.compileDirectory + '/' + module.wrapperName() + '.ngc',
            vlog + vlogStubs + module.moduleDependency['XST'] + moduleList.topModule.moduleDependency['XST'] + xilinx_xcf,
            [ SCons.Script.Delete(moduleList.compileDirectory + '/' + module.wrapperName() + '.srp'),
              SCons.Script.Delete(moduleList.compileDirectory + '/' + module.wrapperName() + '_xst.xrpt'),
              'xst -intstyle silent -ifn config/' + module.wrapperName() + '.modified.xst -ofn ' + moduleList.compileDirectory + '/' + module.wrapperName() + '.srp',
              '@echo xst ' + moduleList.compileDirectory + ' build complete.' ])

        module.moduleDependency['SYNTHESIS'] = [w]
        SCons.Script.Clean(w,  moduleList.compileDirectory + '/' + module.wrapperName() + '.srp')
    



    topSRP = moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.srp'

    top_netlist = moduleList.env.Command(
        moduleList.compileDirectory + '/' + moduleList.topModule.wrapperName() + '.ngc',
        moduleList.topModule.moduleDependency['VERILOG'] +  moduleList.getAllDependencies('VERILOG_STUB') + moduleList.topModule.moduleDependency['XST'] + moduleList.topModule.moduleDependency['XCF'] + xilinx_xcf ,
        [ SCons.Script.Delete(topSRP),
          SCons.Script.Delete(moduleList.compileDirectory + '/' + moduleList.apmName + '_xst.xrpt'),

          'xst -intstyle silent -ifn config/' + moduleList.topModule.wrapperName() + '.modified.xst -ofn ' + topSRP,
          '@echo xst ' + moduleList.apmName + ' build complete.' ])    

    moduleList.topModule.moduleDependency['SYNTHESIS'] = [top_netlist]
    SCons.Script.Clean(top_netlist, topSRP)
