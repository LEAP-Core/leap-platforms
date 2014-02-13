//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
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

