############################################################################
##
## Rules for building a Verilog simulation vexe
##
############################################################################

vexe_gen_command = \
    BSC + ' ' + BSC_FLAGS_VERILOG + ' -vdir ' + env['DEFS']['ROOT_DIR_HW'] + '/' + env['DEFS']['ROOT_DIR_MODEL'] + '/' + env['DEFS']['TMP_BSC_DIR'] + \
    ' -o $TARGET -verilog -e ' + ROOT_WRAPPER_SYNTH_ID + \
    ' $SOURCES ' + env['DEFS']['GIVEN_BAS']

vbin = env.Command(
    TMP_BSC_DIR + '/' + APM_NAME + '_hw.vexe',
    clean_split(env['DEFS']['GEN_VS'], sep = ' ') + clean_split(env['DEFS']['GIVEN_VERILOGS'], sep = ' ') + clean_split(env['DEFS']['GIVEN_VHDS'], sep = ' ')  + clean_split(env['DEFS']['BDPI_CS'], sep=' '),
    [ vexe_gen_command,
      Delete('directc.sft') ])


vexe = env.Command(
    APM_NAME + '_hw.vexe',
    vbin + SW_EXE,
    [ '@echo "#!/bin/sh" > $TARGET',
      '@echo "./$SOURCE +bscvcd \$*" >> $TARGET',
      '@chmod a+x $TARGET',
      '@ln -fs ' + SW_EXE_OR_TARGET + ' ' + APM_NAME,
      Delete(APM_NAME + '_hw.exe'),
      Delete(APM_NAME + '_hw.errinfo') ])

env.Alias('vexe', vexe)

