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

// All debug output files go in a subdirectory
function String debugPath(String fname) = `DEBUG_LOG_DIR + "/" + fname;


// ========================================================================
//
//   Basic debug file.  No model cycle, no thread context.
//
// ========================================================================

// DEBUG_FILE

// A wrapper for a simulation debugging file.

interface DEBUG_FILE;

    method Action record(Fmt fmt);

endinterface


//
// mkDebugFileNull --
//     Null debug file, will drop everything on the floor. 
//
module mkDebugFileNull#(String fname)
    // interface:
    (DEBUG_FILE);
    method record = ?;
endmodule


//
// mkDebugFile --
//     Standard simulation debugging file.
//
module mkDebugFile#(String fname)
    // interface:
    (DEBUG_FILE);

`ifndef SYNTH

    COUNTER#(32) fpga_cycle <- mkLCounter(0);

    Reg#(File) debugLog <- mkReg(InvalidFile);
    Reg#(Bool) initialized <- mkReg(False);

    rule open (initialized == False);
        let fd <- $fopen(debugPath(fname), "w");
        if (fd == InvalidFile)
        begin
            $display("Error opening debugging logfile " + debugPath(fname));
            $finish(1);
        end

        debugLog <= fd;
        initialized <= True;
    endrule

    rule inc (True);
        fpga_cycle.up();
    endrule

    method Action record(Fmt fmt) if (initialized);
        $fdisplay(debugLog, $format("[%d]: ", fpga_cycle.value()) + fmt);
        $fflush(debugLog);
    endmethod

`else

    // No point in wasting space on debug file for synthesized build.  Xst
    // doesn't get rid of it all.
    DEBUG_FILE n <- mkDebugFileNull(fname);
    return n;

`endif

endmodule
