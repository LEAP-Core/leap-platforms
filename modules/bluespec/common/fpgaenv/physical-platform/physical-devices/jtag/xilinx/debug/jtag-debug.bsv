`include "asim/provides/virtual_platform.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/jtag_device.bsh"
`include "asim/provides/low_level_platform_interface.bsh"

`include "asim/rrr/service_ids.bsh"
`include "asim/rrr/server_stub_JTAGDEBUG.bsh"
`include "asim/rrr/client_stub_JTAGDEBUG.bsh"


// mkApplication

module mkApplication#(VIRTUAL_PLATFORM vp)();

    Clock clock <- exposeCurrentClock();
    Reset reset <- exposeCurrentReset();

    LowLevelPlatformInterface llpi = vp.llpint;
    
    // instantiate stubs
    ServerStub_JTAGDEBUG serverStub <- mkServerStub_JTAGDEBUG(llpi.rrrServer);
    ClientStub_JTAGDEBUG clientStub <- mkClientStub_JTAGDEBUG(llpi.rrrClient);

    //Instantiate Jtag
    JTAG_DEVICE jtag <- mkJTAGDevice(?,clock,reset);

    Reg#(Bool) lastNotFull  <-  mkReg(False);
    Reg#(Bool) lastNotEmpty <-  mkReg(False);

    Reg#(Bool) synced <- mkReg(False);

    rule handleGetChar(synced);
      let char <- serverStub.acceptRequest_GetChar();
      //Only have 4 bits here
      let txChar = {4'h4,truncate(char)}; 
      jtag.driver.send(txChar);
      serverStub.sendResponse_GetChar(txChar);
    endrule

    rule handlePutChar;
      let char <- jtag.driver.receive();
      clientStub.makeRequest_PutChar(char);
      synced <= True;
    endrule

    rule handleStatus; 
      lastNotFull <= jtag.driver.notFull;
      lastNotEmpty <= jtag.driver.notEmpty;
    endrule
 
    rule sendStatus (jtag.driver.notFull != lastNotFull || jtag.driver.notEmpty != lastNotEmpty);
       
          clientStub.makeRequest_StatusUpdate({0,pack(jtag.driver.notFull),pack(lastNotFull),pack(jtag.driver.notEmpty),pack(lastNotEmpty)});
        
    endrule

endmodule