import Vector::*;
import FIFO::*;

`include "asim/provides/umf.bsh"

// MARSHALLER

// A marshaller takes one larger value and breaks it into a stream of n output chunks.
// Chunks are sent out starting from the LS chunk and ending with the MS chunk

interface MARSHALLER#(parameter type in_T, parameter type out_T);

    // Enq a new value
    method Action enq(in_T val, UMF_MSG_LENGTH num_chunks);

    // Look the next chunk.
    method out_T  first();

    // Deq the the chunk.
    method Action deq();

    method Bool notEmpty();
endinterface

module mkMarshaller
    // interface:
        (MARSHALLER#(in_T, out_T))
    provisos
        (Bits#(in_T, in_SZ),
         Bits#(out_T, out_SZ),
         Div#(in_SZ, out_SZ, k__),
         Log#(k__, idx_SZ),
         Add#(a__, idx_SZ, `UMF_MSG_LENGTH_BITS));

    // The absolute maximum index into our chunks
    Integer maxIdx = valueof(k__) - 1;
    
    // The number of chunks in the current message being marshalled
    // (this can be smaller than the absolute maximim because
    //  multiple methods can share a marshaller)
    Reg#(UMF_MSG_LENGTH) numChunks <- mkReg(0);
    
    // A vector to store the current chunks we're marshalling
    Reg#(Vector#(k__, Bit#(out_SZ))) chunks <- mkReg(Vector::replicate(0));
    
    // An index telling which chunk is next.
    Reg#(Bit#(idx_SZ)) idx <- mkReg(0);
    
    // Are we done with the current value?
    Reg#(Bool) done <- mkReg(True);

    // enq
    
    // Add the chunk to the first place in the vector and
    // shift the other elements. Also set the max number of chunks
    // for the next operation.
    
    method Action enq(in_T val, UMF_MSG_LENGTH num_chunks) if (done);
    
        Bit#(in_SZ) pval = pack(val);
        Vector#(k__, Bit#(out_SZ)) new_chunks = newVector();
    
        for (Integer x = 0; x < valueof(k__); x = x + 1)
        begin
         
            Bit#(out_SZ) chunk = 0;
            
            for (Integer y = 0; y < valueof(out_SZ); y = y + 1)
            begin
          
                Integer z = x * valueof(out_SZ) + y;
                chunk[y] = (z < valueof(in_SZ)) ? pval[z] : 0;
          
            end
      
            new_chunks[x] = chunk;
      
        end
    
        chunks <= new_chunks;
        
        // assign numChunks
        numChunks <= num_chunks;
        
        // switch to dequeuing mode only if we have > 0 chunks
        if (num_chunks != 0)
        begin
                
            done <= False;
            
        end
      
    endmethod
    
    // first
    
    // Return the next chunk
    
    method out_T first() if (!done);
    
        Bit#(out_SZ) final_value = chunks[idx];
      
        return unpack(final_value);
    
    endmethod
    
    // deq
    
    // Increment the index.
    
    method Action deq() if (!done);
    
        UMF_MSG_LENGTH idx_tmp = zeroExtend(idx);
        
        if (idx_tmp == (numChunks - 1))
        begin
            done <= True;
            idx <= 0;
        end
        else
        begin
            idx <= idx + 1;
        end
    
    endmethod

    // notEmpty

    method Bool notEmpty();
        return ! done;    
    endmethod
endmodule
