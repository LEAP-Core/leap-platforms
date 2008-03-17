import FIFOF::*;
import Vector::*;

`include "umf.bsh"

`define PIPE_NULL       'hFFFFFFFF00000000
`define POLL_INTERVAL   32

// BDPI imports
import "BDPI" function Action                 pipe_init();
import "BDPI" function ActionValue#(Bit#(8))  pipe_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(64)) pipe_read(Bit#(8) handle);
import "BDPI" function Action   pipe_write(Bit#(8) handle, Bit#(32) data);
                  
// types
typedef enum
{
    STATE_init0,
    STATE_init1,
    STATE_ready 
}
STATE
    deriving (Bits, Eq);

// UNIX_PIPE_DRIVER
interface UNIX_PIPE_DRIVER;

    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

// UNIX_PIPE_WIRES
interface UNIX_PIPE_WIRES;

endinterface

// UNIX_PIPE_DEVICE
// By convention a Device is a Driver and a Wires
interface UNIX_PIPE_DEVICE;

  interface UNIX_PIPE_DRIVER driver;
  interface UNIX_PIPE_WIRES  wires;

endinterface
                  
// UNIX pipe module
module mkUNIXPipeDevice
    // interface
                  (UNIX_PIPE_DEVICE);
    
    // state
    Reg#(Bit#(8))  handle      <- mkReg(0);
    Reg#(Bit#(32)) pollCounter <- mkReg(0);
    Reg#(STATE)    state       <- mkReg(STATE_init0);
    
    // buffers
    FIFOF#(UMF_CHUNK) readBuffer  <- mkFIFOF();
    FIFOF#(UMF_CHUNK) writeBuffer <- mkFIFOF();

    // ==============================================================
    //                            Rules
    // ==============================================================

    // poll cycle
    rule cycle_poll_counter(state == STATE_ready && pollCounter != 0);
        pollCounter <= pollCounter - 1;
    endrule

    // initialize C code
    rule initialize(state == STATE_init0);
        pipe_init();
        state <= STATE_init1;
    endrule

    // another rule needed to initialize C code
    rule open_C_channel(state == STATE_init1);
        Bit#(8) wire_out <- pipe_open(0);
        handle <= wire_out;
        state  <= STATE_ready;
    endrule

    // probe C code for incoming chunk
    rule read_bdpi (state == STATE_ready && pollCounter == 0);
        Bit#(64) data <- pipe_read(handle);
        if (data != `PIPE_NULL)
        begin
            UMF_CHUNK chunk = truncate(data);
            readBuffer.enq(chunk);
        end
        pollCounter <= `POLL_INTERVAL;
    endrule

    // write chunk from write buffer into C code
    rule write_bdpi (state == STATE_ready);
        UMF_CHUNK chunk = writeBuffer.first();
        writeBuffer.deq();
        pipe_write(handle, chunk);
    endrule

    // ==============================================================
    //                          Methods
    // ==============================================================
    
    // driver interface
    interface UNIX_PIPE_DRIVER driver;
        
        // read
        method ActionValue#(UMF_CHUNK) read();
            UMF_CHUNK chunk = readBuffer.first();
            readBuffer.deq();
            return chunk;
        endmethod

        // write
        method Action write(UMF_CHUNK chunk);
            writeBuffer.enq(chunk);
        endmethod
        
    endinterface
    
    // wires interface
    interface UNIX_PIPE_WIRES wires;
        
    endinterface

endmodule
