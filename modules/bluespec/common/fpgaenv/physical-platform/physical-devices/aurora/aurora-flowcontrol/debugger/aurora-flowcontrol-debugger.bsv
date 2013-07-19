//
// Copyright (C) 2011 Massachusetts Institute of Technology
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

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.


import Clocks::*;
import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import Connectable::*;
import GetPut::*;
import Vector::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/librl_bsv_storage.bsh"
`include "awb/provides/aurora_driver.bsh"
`include "awb/provides/aurora_device.bsh"
`include "awb/provides/stdio_service.bsh"
`include "awb/provides/soft_services.bsh"
`include "awb/provides/soft_strings.bsh"
`include "awb/provides/soft_connections.bsh"

// Provides a debugging interface to this specific driver implementation. 
module [CONNECTED_MODULE] mkAuroraDebugger#(Integer ifcNum, AURORA_COMPLEX_DRIVER targetDriver) (Empty);

    STDIO#(Bit#(64)) stdio <- mkStdIO();  

    // periodic debug printout
    let aurSndMsg <- getGlobalStringUID("Aurora %d channel_up %x, lane_up %x, error_count %x rx_count %x tx_count %x rx_fifo_count %x tx_fifo_count %x\n");
    let aurFCMsg <- getGlobalStringUID("Flowcontrol tokens RX'ed: %x, Flowcontrol tokens TX'ed %x\n");
    let aurCreditMsg <- getGlobalStringUID("Aurora credit_underflow %x, rx_credit %x, tx_credit %x, data_drops %x  heartbeat_count %x\n");
    let txDebugMsg <- getGlobalStringUID("TXBuffer %x\n");
    let rxDebugMsg <- getGlobalStringUID("RXBuffer %x\n");

    Reg#(Bit#(26)) counter <- mkReg(0);

    rule printf;
        counter <= counter + 1;
        
        if(counter + 1 == 0) 
        begin
            stdio.printf(aurSndMsg, list8(fromInteger(ifcNum),zeroExtend(pack(targetDriver.channel_up)), zeroExtend(pack(targetDriver.lane_up)), zeroExtend(targetDriver.error_count), zeroExtend(targetDriver.rx_count), zeroExtend(targetDriver.tx_count), zeroExtend(pack(targetDriver.rx_fifo_count)), zeroExtend(pack(targetDriver.tx_fifo_count))));
        end
        else if (counter + 1 == 1)
        begin
            stdio.printf(aurCreditMsg, list5(zeroExtend(pack(targetDriver.credit_underflow)), zeroExtend(pack(targetDriver.rx_credit)), zeroExtend(targetDriver.tx_credit), zeroExtend(pack(targetDriver.data_drops)), zeroExtend(pack(targetDriver.heartbeat_count))));
        end
        else if (counter + 1 == 2)
        begin
            stdio.printf(aurFCMsg, list2(zeroExtend(pack(targetDriver.rx_fc)), zeroExtend(pack(targetDriver.tx_fc))));
        end
    endrule

endmodule

