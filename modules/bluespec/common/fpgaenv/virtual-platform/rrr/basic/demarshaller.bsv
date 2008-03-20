import Vector::*;
import FIFO::*;

`include "channelio.bsh"
`include "rrr.bsh"
`include "asim/rrr/rrr_service_ids.bsh"
`include "umf.bsh"

// RRR parameter de-marshaller

typedef enum
{
    DEM_STATE_idle,
    DEM_STATE_active
}
DEM_STATE
    deriving (Bits, Eq);

// outbits *has* to be a multiple of inbits
interface DeMarshaller#(numeric type inbits_t, numeric type outbits_t);
    method Action                        start(UMF_MSG_LENGTH nchunks);
    method Action                        enq(Bit#(inbits_t) chunk);
    method ActionValue#(Bit#(outbits_t)) deq();
endinterface

module mkDeMarshaller(DeMarshaller#(inbits_t, outbits_t))
    provisos(Add#(a__, inbits_t, outbits_t));

    // compute degree
    Integer inbits    = valueof(inbits_t);
    Integer outbits   = valueof(outbits_t);
    Integer remainder = outbits % inbits;
    Integer degree    = remainder == 0     ?
                        (outbits / inbits) :
                        (outbits / inbits) + 1;

    // instantiate output register
    Reg#(Bit#(inbits_t))  outreg[degree];
    for (Integer i = 0; i < degree; i=i+1)
        outreg[i] <- mkReg(0);

    // output release register
    Reg#(UMF_MSG_LENGTH) outchunks <- mkReg(0);

    // current index
    Reg#(UMF_MSG_LENGTH) index <- mkReg(0);

    // state
    Reg#(DEM_STATE) state <- mkReg(DEM_STATE_idle);

    // set up a bit-vector that generates the output wires
    Bit#(outbits_t) outval = '0;

    // special-case last chunk
    outval [ outbits-1 : (degree-1)*inbits ] = outreg[ degree-1 ];

    // other chunks
    for (Integer i = 0; i < degree-1; i=i+1)
    begin
        outval[ (i+1)*inbits - 1 : i*inbits ] = outreg[i];
    end

    // methods
    method Action start(UMF_MSG_LENGTH nchunks) if (state == DEM_STATE_idle);
        index <= 0;
        outchunks <= nchunks;
        state <= DEM_STATE_active;
    endmethod

    method Action enq(Bit#(inbits_t) chunk) if (state == DEM_STATE_active &&
                                                index != outchunks);
        outreg[index] <= chunk;
        index <= index + 1;
    endmethod

    method ActionValue#(Bit#(outbits_t)) deq() if (state == DEM_STATE_active &&
                                                   index == outchunks);
        state <= DEM_STATE_idle;
        return outval;
    endmethod

endmodule
