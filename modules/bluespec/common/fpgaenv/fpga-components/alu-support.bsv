//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

//
// Author: Michael Adler
//
// alu-support.bsv -- Methods for constructing integer arithmetic logic units.
//

import Vector::*;
import RWire::*;

`include "asim/provides/libfpga_bsv_base.bsh"


// ===================================================================
//
// PUBLIC DATA STRUCTURES
//
// ===================================================================


//
// HASIM_COMPACT_MUL implements an nBits x nBits multiplier returning
// nBits * 2.
//
// resp() blocks until a result is available.
//
interface HASIM_COMPACT_MUL#(numeric type nBits);
    
    method Action req(Bit#(nBits) arg0, Bit#(nBits) arg1);
    method ActionValue#(Bit#(TMul#(nBits, 2))) resp();
    
endinterface: HASIM_COMPACT_MUL


//
// HASIM_UNBUFFERED_PIPELINED_MUL is an interface to a raw Xilinx multiplication
// pipeline.  There are no buffers or registers.  If result data is not consumed
// on the correct cycle it will be lost.
//
// The read() method returns a Maybe#() to indicate cycles on which data is
// valid, so callers do not need to know the pipe depth..  Data flows FIFO
// through the pipeline.
//
interface HASIM_UNBUFFERED_PIPELINED_MUL#(numeric type nBits, numeric type nStages);
    
    method Action write(Bit#(nBits) arg0, Bit#(nBits) arg1);
    method Maybe#(Bit#(TMul#(nBits, 2))) read();
    
endinterface: HASIM_UNBUFFERED_PIPELINED_MUL


// ===================================================================
//
// PRIVATE DATA STRUCTURES
//
// ===================================================================

typedef enum
{
    STATE_MUL_FREE,
    STATE_MUL_BUSY,
    STATE_MUL_DONE
}
STATE_MUL
    deriving (Bits, Eq);

//
// mkPipelinedUnsignedMul --
//
//    Raw Xilinx nBits x nBits multiplier pipeline, returning a result twice
//    the width of the input.
//
module mkPipelinedUnsignedMul
    // interface:
        (HASIM_UNBUFFERED_PIPELINED_MUL#(nBits, nStages))
    provisos (Alias#(Bit#(nBits),           t_INPUT),
              Alias#(Bit#(TMul#(nBits, 2)), t_RESULT),
       
              // These are required by the compiler due to poor constant folding:
              Add#(nBits, nBits, TMul#(nBits, 2)));

    let v_nStages = valueOf(nStages);

    //
    // Storage used in pipeline below.
    //
    Vector#(nStages, Reg#(t_RESULT)) pipe = newVector();
    Vector#(nStages, Reg#(Bool)) pipeValid = newVector();

    for (Integer s = 0; s < v_nStages; s = s + 1)
    begin
        pipe[s] <- mkRegU();
        pipeValid[s] <- mkReg(False);
    end

    Wire#(t_RESULT) pipeOut <- mkBypassWire();
    Wire#(Bool) pipeValidOut <- mkBypassWire();

    Reg#(t_INPUT) buf0 <- mkRegU();
    Reg#(t_INPUT) buf1 <- mkRegU();
    Reg#(Bool)    bufValid <- mkReg(False);

    Reg#(t_INPUT) input0 <- mkRegU();
    Reg#(t_INPUT) input1 <- mkRegU();
    Reg#(Bool)    inputValid <- mkReg(False);

    //
    // pipeline --
    //
    //    This is the key rule of the multiplier.  It provides registers for a
    //    pipeline both on input to and output from the multiply.  These registers
    //    are recognized by Xilinx Xst and converted to the DSP48 multiplier
    //    block.  The Xst manual states that all pipeline registers must be
    //    controlled only by the clock.
    //
    //    The Bluespec attempts to mimic the following Verilog from the Xst
    //    manual:
    //
    //        module v_multipliers_2(clk, A, B, MULT);
    //
    //            input clk;
    //            input [17:0] A;
    //            input [17:0] B;
    //            output [35:0] MULT;
    //            reg [35:0] MULT;
    //            reg [17:0] a_in, b_in;
    //            wire [35:0] mult_res;
    //            reg [35:0] pipe_1, pipe_2, pipe_3;
    //
    //            assign mult_res = a_in * b_in;
    //
    //            always @(posedge clk)
    //            begin
    //                a_in <= A; b_in <= B;
    //                pipe_1 <= mult_res;
    //                pipe_2 <= pipe_1;
    //                pipe_3 <= pipe_2;
    //                MULT <= pipe_3;
    //            end
    //        endmodule
    //
    (* fire_when_enabled *)
    rule pipelineData (True);
        // Get pair of numbers to multiply and store them in first register pair.
        buf0 <= input0;
        buf1 <= input1;
        
        // Do the multiply
        pipe[0] <= pack(unsignedMul(unpack(buf0), unpack(buf1)));

        // Push the result through a set of registers.  These will be turned into
        // a pipelined multiply.
        for (Integer s = 1; s < v_nStages; s = s + 1)
        begin
            pipe[s] <= pipe[s - 1];
        end

        // Send output to read() method
        pipeOut <= pipe[v_nStages - 1];
    endrule

    //
    // pipelineCtrl mirrors the pipeline flow of pipelineData so a valid bit
    // will emerge from the control pipeline on cycles where valid data
    // emerges from the data pipeline above.
    //
    (* fire_when_enabled *)
    rule pipelineCtrl (True);
        bufValid <= inputValid;

        pipeValid[0] <= bufValid;

        for (Integer s = 1; s < v_nStages; s = s + 1)
        begin
            pipeValid[s] <= pipeValid[s - 1];
        end

        // Send output to read() method
        pipeValidOut <= pipeValid[v_nStages - 1];
    endrule

    //
    // Track whether write was called this cycle.  If it was then set the valid
    // bit to flow down the pipeline.
    //

    PulseWire write_called <- mkPulseWire();
    RWire#(Bit#(nBits)) incoming0 <- mkRWire();
    RWire#(Bit#(nBits)) incoming1 <- mkRWire();

    (* fire_when_enabled *)
    rule checkForWrite (True);
        inputValid <= write_called;
        if (incoming0.wget() matches tagged Valid .i0)
            input0 <= i0;
        if (incoming1.wget() matches tagged Valid .i1)
            input1 <= i1;
    endrule

    //
    // New input to push into the pipeline.
    //
    method Action write(Bit#(nBits) arg0, Bit#(nBits) arg1);
        write_called.send();
        incoming0.wset(arg0);
        incoming1.wset(arg1);
    endmethod

    //
    // Read pipe output.  Valid bit indicates whether result corresponds to a
    // previous write().  There is no buffering in the pipe, so read() must happen
    // at the correct cycle.
    //
    method Maybe#(t_RESULT) read();
        return pipeValidOut ? tagged Valid pipeOut : tagged Invalid;
    endmethod

endmodule


//
// mkCompactUnsignedMul --
//
//    Multiply two numbers yielding a result 2x the size of the inputs.
//    The product is computed as the sum of four partial products to use
//    fewer multipliers and take advantage of the multiplier pipeline.
//
module mkCompactUnsignedMul
    // interface:
        (HASIM_COMPACT_MUL#(nBits))
    provisos (Alias#(Bit#(TMul#(nBits, 2)), t_RESULT),

              // These are required by the compiler due to poor constant folding:
              Add#(a__, TMul#(TDiv#(nBits, 2), 2), TMul#(nBits, 2)),
              Add#(b__, TMul#(3, TDiv#(nBits, 2)), TMul#(nBits, 2)),
              Add#(c__, TMul#(TDiv#(nBits, 2), 2), TMul#(3, TDiv#(nBits, 2))),
              Add#(TDiv#(nBits, 2), TDiv#(nBits, 2), TMul#(TDiv#(nBits, 2), 2)));


    //
    // The multiplier pipeline.  The multiplier inputs are half the size
    // of nBits because the full result is the sum of four partial products.
    //
    // The second term is the pipeline depth.  There is probably a better way
    // to select from a series of constant values than this.  The expression
    //
    //    Pipe Stages = 2 * log2(nBits) - 7
    //
    // appears to work for Virtex 5.  The expression was tested for
    // nBits of 32, 64 and 128.
    //
    HASIM_UNBUFFERED_PIPELINED_MUL#(
       TDiv#(nBits, 2),
       TSub#(TMul#(2, TLog#(nBits)), 7)) mult <- mkPipelinedUnsignedMul();

    let v_nBits = valueOf(nBits);

    Reg#(STATE_MUL) state <- mkReg(STATE_MUL_FREE);
    
    // Storage for output value
    Reg#(t_RESULT) result <- mkRegU();

    //
    // drain --
    //     Drain four partial products.  The order of the results coming
    //     from the pipe minimizes the number and sizes of additions.
    //

    Reg#(Bit#(2)) outPos <- mkReg(0);

    (* fire_when_enabled *)
    rule drain (state == STATE_MUL_BUSY);
        if (mult.read() matches tagged Valid .m)
        begin
            case (outPos)
                // Low half of result
                0:  result[v_nBits - 1 : 0] <= m;
                
                // High half of result
                1:  result[(v_nBits * 2) - 1 : v_nBits] <= m;
                
                // High 3/4 of result (need to include top 1/4 due to rounding)
                2, 3:
                begin
                    // Extend to 3/4 size of result
                    Bit#(TMul#(3, TDiv#(nBits, 2))) m_ext = zeroExtend(m);

                    // Add new partial product to existing result
                    result[(v_nBits * 2) - 1 : v_nBits / 2] <=
                        result[(v_nBits * 2) - 1 : v_nBits / 2] + m_ext;
                end
            endcase

            if (outPos == 3)
                state <= STATE_MUL_DONE;

            outPos <= outPos + 1;
        end
    endrule

    //
    // pushPartialProducts --
    //    Push the 3 remaining pairs through the pipeline.  The order of
    //    pairs must correspond to the expected order in "drain" above.
    //
    Reg#(Bit#(2)) inPos <- mkReg(0);
    Reg#(Bit#(nBits)) x_arg0 <- mkRegU();
    Reg#(Bit#(nBits)) x_arg1 <- mkRegU();

    rule pushPartialProducts ((inPos != 0) && (state == STATE_MUL_BUSY));
        let input0 = (inPos[0] == 1) ? x_arg0[v_nBits - 1 : v_nBits / 2] : x_arg0[v_nBits / 2 - 1 : 0];
        let input1 = (inPos[0] != inPos[1]) ? x_arg1[v_nBits - 1 : v_nBits / 2] : x_arg1[v_nBits / 2 - 1 : 0];

        mult.write(input0, input1);

        inPos <= inPos + 1;
    endrule


    //
    // req --
    //     Trigger the multiplication. 
    //
    method Action req(Bit#(nBits) arg0, Bit#(nBits) arg1) if (state == STATE_MUL_FREE);
        // Save arguments
        x_arg0 <= arg0;
        x_arg1 <= arg1;

        // Start the first pair
        let input0 = arg0[v_nBits / 2 - 1 : 0];
        let input1 = arg1[v_nBits / 2 - 1 : 0];
        mult.write(input0, input1);

        inPos <= 1;
        state <= STATE_MUL_BUSY;
        result <= 0;
    endmethod

    //
    // resp --
    //     Return result.
    //
    method ActionValue#(t_RESULT) resp() if (state == STATE_MUL_DONE);
        state <= STATE_MUL_FREE;
        return result;
    endmethod
    
endmodule



//
// mkCompactSignedMul --
//
//     Signed multiply.  Uses unsigned multiply to compute the product of the
//     absolute values of the inputs, then sets the sign in resp().
//
module mkCompactSignedMul
    // interface:
        (HASIM_COMPACT_MUL#(nBits))
    provisos (Alias#(Bit#(TMul#(nBits, 2)), t_RESULT),

              // These are required by the compiler due to poor constant folding:
              Add#(a__, TMul#(TDiv#(nBits, 2), 2), TMul#(nBits, 2)),
              Add#(b__, TMul#(3, TDiv#(nBits, 2)), TMul#(nBits, 2)),
              Add#(c__, TMul#(TDiv#(nBits, 2), 2), TMul#(3, TDiv#(nBits, 2))),
              Add#(TDiv#(nBits, 2), TDiv#(nBits, 2), TMul#(TDiv#(nBits, 2), 2)));

       
    HASIM_COMPACT_MUL#(nBits) umul <- mkCompactUnsignedMul();

    Reg#(Bool) isNegative <- mkRegU();

    method Action req(Bit#(nBits) arg0, Bit#(nBits) arg1);
        let v_nBits = valueOf(nBits);

        // Result will be negative if exactly one input is negative
        isNegative <= (arg0[v_nBits - 1] ^ arg1[v_nBits - 1]) == 1;
    
        // Make arguments positive.  Sign will be set on output.
        let abs_arg0 = arg0[v_nBits - 1] == 0 ? arg0 : -arg0;
        let abs_arg1 = arg1[v_nBits - 1] == 0 ? arg1 : -arg1;

        umul.req(abs_arg0, abs_arg1);
    endmethod

    //
    // resp --
    //     Return result.
    //
    method ActionValue#(t_RESULT) resp();
        let m <- umul.resp();
        return isNegative ? -m : m;
    endmethod

endmodule
