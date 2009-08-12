
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/front_panel.bsh"
`include "asim/provides/central_cache.bsh"
`include "asim/provides/scratchpad_memory.bsh"
`include "asim/provides/shared_memory.bsh"
`include "asim/provides/starter_device.bsh"
`include "asim/provides/streams.bsh"

interface VIRTUAL_DEVICES;

    interface FrontPanel frontPanel;
    interface CENTRAL_CACHE_VIRTUAL_DEVICE centralCache;
    interface SCRATCHPAD_MEMORY_VDEV scratchpadMemory;
    interface SHARED_MEMORY sharedMemory;
    interface Streams streams;
    interface STARTER starter;
    // TODO: add
    // interface STATS stats;
    // interface PARAMS params;
    // interface DEBUG_SCAN debug;

endinterface

module mkVirtualDevices#(LowLevelPlatformInterface llpint)
    // interface:
        (VIRTUAL_DEVICES);

    let fp  <- mkFrontPanel(llpint);
    // TODO: use the new Stats device for real stats
    let cc  <- mkCentralCache(llpint, ?);
    let sp  <- mkMemoryVirtualDevice(llpint, cc);
    let sh  <- mkSharedMemory(llpint);
    let st  <- mkStarter(llpint);
    let str <- mkStreams(llpint);
    
    interface frontPanel = fp;
    interface centralCache = cc;
    interface scratchpadMemory = sp;
    interface sharedMemory = sh;
    interface starter = st;
    interface streams = str;

endmodule
