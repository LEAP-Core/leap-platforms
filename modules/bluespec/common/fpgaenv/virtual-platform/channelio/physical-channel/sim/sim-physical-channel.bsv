import FIFOF::*;
import Vector::*;

`include "physical_platform.bsh"
`include "umf.bsh"

`define PCH_NULL        'hFFFFFFFF00000000
`define POLL_INTERVAL   32

// BDPI imports
import "BDPI" function Action                 pch_init();
import "BDPI" function ActionValue#(Bit#(8))  pch_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(64)) pch_read(Bit#(8) handle);
import "BDPI" function Action   pch_write(Bit#(8) handle, Bit#(32) data);
                  
// types
typedef enum
{
    STATE_init0,
    STATE_init1,
    STATE_ready 
}
STATE
    deriving (Bits, Eq);
                  
// physical channel interface
interface PhysicalChannel;
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
endinterface

// physical channel module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
                  (PhysicalChannel);
    
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
        pch_init();
        state <= STATE_init1;
    endrule

    // another rule needed to initialize C code
    rule open_C_channel(state == STATE_init1);
        Bit#(8) wire_out <- pch_open(0);
        handle <= wire_out;
        state  <= STATE_ready;
    endrule

    // probe C code for incoming chunk
    rule read_bdpi (state == STATE_ready && pollCounter == 0);
        Bit#(64) data <- pch_read(handle);
        if (data != `PCH_NULL)
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
        pch_write(handle, chunk);
    endrule

    // ==============================================================
    //                          Methods
    // ==============================================================

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

endmodule
