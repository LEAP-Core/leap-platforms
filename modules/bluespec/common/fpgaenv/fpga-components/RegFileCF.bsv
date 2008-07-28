import RegFile::*;

// RegFileCF: a BDPI-based implementation of a conflict free register file

typedef Bit#(64) Handle;

import "BDPI"
function ActionValue#(Handle) regfile_cf_init(int addr_sz, int data_sz, int depth);

import "BDPI"
function Action regfile_cf_upd(Handle h, addr_t a, data_t d)
                    provisos (Bits#(addr_t, sa),
                              Bits#(data_t, sd));

import "BDPI"
function data_t regfile_cf_sub(Handle h, addr_t a)
                    provisos (Bits#(addr_t, sa),
                              Bits#(data_t, sd));

module mkRegFileCF#(Integer depth)
        (RegFile#(addr_t,data_t))
            provisos (Bits#(addr_t, sa),
                      Bits#(data_t, sd));

    Reg#(Maybe#(Handle)) h <- mkReg(Invalid);

    rule init (h == Invalid);
        let ptr <- regfile_cf_init(fromInteger(valueof(sa)), fromInteger(valueof(sd)), fromInteger(depth));
        h <= Valid(ptr);
    endrule

    // expected schedule: (upd,sub) CF (upd,sub)

    method Action upd(addr_t a, data_t d) if (h matches tagged Valid .hh);
        regfile_cf_upd(hh, a, d);
    endmethod

    method data_t sub(addr_t a) if (h matches tagged Valid .hh);
        return regfile_cf_sub(hh, a);
    endmethod
endmodule

