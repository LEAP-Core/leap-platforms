
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/front_panel.bsh"
`include "asim/provides/central_cache.bsh"
`include "asim/provides/scratchpad_memory.bsh"
`include "asim/provides/shared_memory.bsh"
`include "asim/provides/starter_device.bsh"
`include "asim/provides/common_utility_devices.bsh"

interface VIRTUAL_DEVICES;

    interface FRONT_PANEL frontPanel;
    interface CENTRAL_CACHE_VIRTUAL_DEVICE centralCache;
    interface SCRATCHPAD_MEMORY_VDEV scratchpadMemory;
    interface SHARED_MEMORY sharedMemory;
    interface STARTER starter;
    interface COMMON_UTILITY_DEVICES commonUtilities;

endinterface

module mkVirtualDevices#(LowLevelPlatformInterface llpint)
    // interface:
        (VIRTUAL_DEVICES);

    let fp  <- mkFrontPanel(llpint);
    // TODO: use the new Stats device for real stats
    let cc  <- mkCentralCache(llpint);
    let sp  <- mkMemoryVirtualDevice(llpint, cc);
    let sh  <- mkSharedMemory(llpint);
    let st  <- mkStarter(llpint);
    let com <- mkCommonUtilityDevices(llpint);

    interface frontPanel = fp;
    interface centralCache = cc;
    interface scratchpadMemory = sp;
    interface sharedMemory = sh;
    interface starter = st;
    interface commonUtilities = com;

endmodule
