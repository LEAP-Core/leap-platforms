
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/front_panel.bsh"
`include "asim/provides/starter_device.bsh"
`include "asim/provides/common_utility_devices.bsh"

interface VIRTUAL_DEVICES;

    interface FRONT_PANEL frontPanel;
    interface STARTER starter;
    interface COMMON_UTILITY_DEVICES commonUtilities;

endinterface

module mkVirtualDevices#(LowLevelPlatformInterface llpint)
    // interface:
        (VIRTUAL_DEVICES);

    let fp  <- mkFrontPanel(llpint);
    // TODO: use the new Stats device for real stats
    let st  <- mkStarter(llpint);
    let com <- mkCommonUtilityDevices(llpint);

    interface frontPanel = fp;
    interface starter = st;
    interface commonUtilities = com;

endmodule
