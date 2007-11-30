import Vector::*;

`include "toplevel_wires.bsh"

`define CIO_NUM_READ_CHANNELS   2
`define CIO_NUM_WRITE_CHANNELS  2

typedef Bit#(32) CIO_Chunk;

// read/write port interfaces
interface CIOReadPort;
    method ActionValue#(CIO_Chunk) read();
endinterface

interface CIOWritePort;
    method Action write(CIO_Chunk data);
endinterface

// channelio interface
interface ChannelIO;
    interface Vector#(`CIO_NUM_READ_CHANNELS, CIOReadPort)   readPorts;
    interface Vector#(`CIO_NUM_WRITE_CHANNELS, CIOWritePort) writePorts;
endinterface

module mkChannelIO (ChannelIO);

    return ?;

endmodule
