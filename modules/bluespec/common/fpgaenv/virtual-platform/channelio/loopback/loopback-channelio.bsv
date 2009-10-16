import FIFOF::*;
import Vector::*;

`include "physical_platform.bsh"
`include "physical_channel.bsh"
`include "umf.bsh"

// read/write port interfaces
interface CIOReadPort;
    method ActionValue#(UMF_PACKET) read();
endinterface

interface CIOWritePort;
    method Action write(UMF_PACKET data);
endinterface

// channelio interface
interface CHANNEL_IO;
    interface Vector#(`CIO_NUM_CHANNELS, CIOReadPort)  readPorts;
    interface Vector#(`CIO_NUM_CHANNELS, CIOWritePort) writePorts;
endinterface

// channelio module
module mkChannelIO#(PHYSICAL_DRIVERS drivers) (CHANNEL_IO);

    // physical channel
    PHYSICAL_CHANNEL physicalChannel <- mkPhysicalChannel(drivers);

    // ==============================================================
    //                        Loopback logic
    // ==============================================================

    rule loopback;
      let chunk <- physicalChannel.read();
      $display("chunk %h", chunk);
      physicalChannel.write(chunk);
    endrule	 

    // ==============================================================
    //                        Set Interfaces
    // ==============================================================

    // since we are creating a loopback device, and don't care about
    // anything above us in the stack, set the interfaces to null

    interface readPorts = ?;
    interface writePorts = ?;

endmodule
