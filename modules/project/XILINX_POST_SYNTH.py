import os
import re
import sys
import SCons.Script
from model import  *
from xilinx_ucf import *
from xilinx_bmm import *
from xilinx_ngd import *
from xilinx_map import *
from xilinx_par import *
from xilinx_bitgen import *
from xilinx_loader import *

#this might be better implemented as a 'Node' in scons, but 
#I want to get something working before exploring that path

class PostSynthesize():
  def __init__(self, moduleList):

    fpga_part_xilinx = moduleList.env['DEFS']['FPGA_PART_XILINX']
    xilinx_apm_name = moduleList.compileDirectory + '/' + moduleList.apmName
    # Concatenate UCF files
    UCF(moduleList)

    moduleList.dump()

    BMM(moduleList)

    moduleList.dump()
      
    NGD(moduleList)

    moduleList.dump()

    MAP(moduleList)

    moduleList.dump()

    PAR(moduleList)

    moduleList.dump()

    BITGEN(moduleList)

    moduleList.dump()

    LOADER(moduleList)
    
