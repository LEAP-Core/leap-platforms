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
// The standard Bluespec "mkCounter" does not support simultaneous up/down
// calls.  This code, taken mostly from the Bluespec documentation does.
//

interface COUNTER#(numeric type nBits);

    method Bit#(nBits) value();

    method Action up();
    method Action upBy(Bit#(nBits) c);

    method Action down();
    method Action downBy(Bit#(nBits) c);

    method Action setC(Bit#(nBits) newVal);

endinterface: COUNTER


module mkLCounter#(Bit#(nBits) initial_value)
    // interface:
        (COUNTER#(nBits));

    // Counter value
    Reg#(Bit#(nBits)) ctr <- mkReg(initial_value);

    Wire#(Bit#(nBits)) up_by   <- mkDWire(0);
    Wire#(Bit#(nBits)) down_by <- mkDWire(0);
    RWire#(Bit#(nBits)) setc_called <- mkRWire();

    (* fire_when_enabled, no_implicit_conditions *)
    rule update_counter;
        if (setc_called.wget() matches tagged Valid .v)
            ctr <= v + up_by - down_by;
        else
            ctr <= ctr + up_by - down_by;
    endrule

    method Bit#(nBits) value();
        return ctr;
    endmethod

    method Action up();
        up_by <= 1;
    endmethod

    method Action upBy(Bit#(nBits) c);
        up_by <= c;
    endmethod

    method Action down();
        down_by <= 1;
    endmethod

    method Action downBy(Bit#(nBits) c);
        down_by <= c;
    endmethod

    method Action setC(Bit#(nBits) newVal);
        setc_called.wset(newVal);
    endmethod

endmodule: mkLCounter


//
// COUNTER_Z interface is the same as a standard Counter but has a testable
// zero bit in order to avoid having to read the whole counter to check for 0.
//
interface COUNTER_Z#(numeric type nBits);

    method Bool isZero();
    method Bit#(nBits) value();

    method Action up();
    method Action down();
    method Action setC(Bit#(nBits) newVal);

endinterface: COUNTER_Z


module mkLCounter_Z#(Bit#(nBits) initial_value)
    // interface:
        (COUNTER_Z#(nBits));

    // Counter value
    Reg#(Bit#(nBits)) ctr <- mkReg(initial_value);

    // Is counter 0?
    Reg#(Bool) zero <- mkReg(initial_value == 0);

    PulseWire up_called   <- mkPulseWire();
    PulseWire down_called <- mkPulseWire();
    RWire#(Bit#(nBits)) setc_called <- mkRWire();

    (* fire_when_enabled, no_implicit_conditions *)
    rule update_counter;
        let new_value = ctr;

        if (setc_called.wget() matches tagged Valid .v)
            new_value = v;

        if (up_called == down_called)
            noAction;
        else if (up_called)
            new_value = new_value + 1;
        else
            new_value = new_value - 1;

        zero <= (new_value == 0);
        ctr <= new_value;
    endrule

    method Bool isZero();
        return zero;
    endmethod

    method Bit#(nBits) value();
        return ctr;
    endmethod

    method Action up();
        up_called.send();
    endmethod

    method Action down();
        down_called.send();
    endmethod

    method Action setC(Bit#(nBits) newVal);
        setc_called.wset(newVal);
    endmethod

endmodule: mkLCounter_Z
