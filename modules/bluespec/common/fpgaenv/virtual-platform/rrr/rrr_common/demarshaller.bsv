import Vector::*;
import FIFO::*;

`include "asim/provides/umf.bsh"
`include "asim/provides/librl_bsv_base.bsh"

// DeMarshaller

// A de-marshaller takes n input "chunks" and produces one larger value.
// Chunks are received starting from the MS chunk and ending with the LS chunk

// Overall RRR service-stub flow control primarily lives in this code.
// The stub itself initiates a demarshalling sequence by calling "start"
// and passing in the number of chunks after which the demarshaller should
// activate the output. The demarshaller will not accept a new start
// request until the previous sequence has been read out. The stub itself
// does not have to explicitly maintain any other flow-control related
// state.

// types
typedef enum
{
    STATE_idle,
    STATE_queueing
}
STATE
    deriving(Bits, Eq);

// interface
interface DEMARSHALLER#(parameter type in_T, parameter type out_T);
    
    // start a demarshalling sequence
    method Action start(UMF_MSG_LENGTH nchunks);
        
    // insert a chunk
    method Action insert(in_T chunk);
        
    // read the whole completed value and delete it
    method ActionValue#(out_T) readAndDelete();

    // read the whole completed value
    method out_T peek();

endinterface

// module
module mkDeMarshaller
    // interface:
        (DEMARSHALLER#(in_T, out_T))
    provisos
        (Bits#(in_T, in_SZ),
         Bits#(out_T, out_SZ),
         Div#(out_SZ, in_SZ, k__));
    
    // =============== state ================
    
    // degree (max number of chunks) of our shift register
    Integer degree = valueof(k__);
    
    // shift register we fill up as chunks come in.
    Vector#(k__, Reg#(Bit#(in_SZ))) chunks = newVector();
    
    // fill in the vector
    for (Integer x = degree - 1; x >= 0; x = x - 1)
    begin
        chunks[x] <- mkReg(0);
    end
    
    // number of chunks remaining in current sequence
    Reg#(UMF_MSG_LENGTH) chunksRemaining <- mkReg(0);
    
    // demarshaller state
    Reg#(STATE) state <- mkReg(STATE_idle);
    
    // =============== methods ===============
    
    // start a demarshalling sequence
    method Action start(UMF_MSG_LENGTH nchunks) if (state == STATE_idle);
        
        // initialize number of chunks in sequence
        chunksRemaining <= nchunks;
        state <= STATE_queueing;
        
    endmethod
    
    // add the chunk to the first place in the vector and
    // shift the other elements.
    method Action insert(in_T chunk) if (state == STATE_queueing &&
                                         chunksRemaining != 0);
    
        // newer chunks are closer to the LSB.
        if (degree != 0)
        begin
            chunks[0] <= pack(chunk);
        end
      
        // Do the shift with a for loop
        for (Integer x = 1; x < degree; x = x+1)
        begin
            chunks[x] <= chunks[x-1];
        end
        
        // decrement chunks remaining
        chunksRemaining <= chunksRemaining - 1;
        
    endmethod
    
    // return the entire vector
    method ActionValue#(out_T) readAndDelete() if (state == STATE_queueing &&
                                                   chunksRemaining == 0);
    
 
        Bit#(out_SZ) final_val = truncateNP(pack(readVReg(chunks)));
         
        // switch to idle state
        state <= STATE_idle;
    
        // return
        return unpack(final_val);
    
    endmethod

    // return the entire vector
    method out_T peek() if (state == STATE_queueing &&
                            chunksRemaining == 0);
    
        Bit#(out_SZ) final_val = 0;
      
        // this is where the good stuff happens
        // fill in the result one bit at a time
        for (Integer x = 0; x < valueof(out_SZ); x = x + 1)
        begin
        
            Integer j = x / valueof(in_SZ);
            Integer k = x % valueof(in_SZ);
            final_val[x] = chunks[j][k];
      
        end
        
        // return
        return unpack(final_val);
    
    endmethod

endmodule
