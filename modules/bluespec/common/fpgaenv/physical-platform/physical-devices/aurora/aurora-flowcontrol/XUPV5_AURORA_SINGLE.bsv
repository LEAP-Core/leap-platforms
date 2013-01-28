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

interface AURORA_WIRES;
	method Action aurora_clk_n((* port="AURORA_GTXQ_IN" *) Bit#(1) clk_n);
	method Action aurora_clk_p((* port="AURORA_GTXQ_IN" *) Bit#(1) clk_p);
	method Action rxp_in(Bit#(1) i);
	method Action rxn_in(Bit#(1) i);
	method Bit#(1) txp_out();
	method Bit#(1) txn_out();
        interface Reset aurora_rst;
	interface Clock aurora_clk;
        interface Reset model_rst;
	interface Clock model_clk;
endinterface


// guarded interface
// Notice that we do a 4 to 1 vectorization here.  This is to exploit the high bandwidth of the link relative to our
// clock frequency.  Ideally, we would choose vectorization intelligently based on MODEL_CLOCK_FREQ and the link
// bandwidth, but I don't have time for that now, and making it a constant gets most of the performance. 
interface AURORA_DRIVER;
    method Action                 write(Bit#(63) tx_word); // txusrclk 
    method Bool                   write_ready(); // txusrclk 
    method Action                 deq(); // rxusrclk0     
    method Bit#(63)               first(); // rxusrclk0     


    // Debugging interface
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bool     credit_underflow;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;
    method Bit#(32) rx_fifo_count;
    method Bit#(32) tx_fifo_count;
    method Bit#(16) tx_credit;
    method Bit#(16) rx_credit;
    method Bit#(16) data_drops;
    method Bit#(32) tx_fc;
    method Bit#(32) rx_fc;
    interface Get#(Bit#(16)) rxDebug; 
    interface Get#(Bit#(16)) txDebug; 

endinterface

interface AURORA_DEVICE;
    (* prefix = "" *)      
    interface AURORA_WIRES wires;
    interface AURORA_DRIVER driver;
endinterface      

// Parameterizations for the aurora flow control interface.
// Eventually, these should be codified as first order parameters.
// Also the width of the interface should automatically adjust based on 
// clock ratios.

typedef 512 BufferSize;
typedef TDiv#(BufferSize,4) AllCredits;
typedef TDiv#(BufferSize,8) HalfCredits;
typedef TMul#(3,TDiv#(BufferSize,16)) ThreeFourthsCredits;


module mkAURORA_FLOWCONTROL#(AURORA_SINGLE_DEVICE_UG ug_device) (AURORA_DEVICE);

    let modelClock <- exposeCurrentClock();

    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();
    let isModelInRst <- isResetAsserted();
    let controllerClk = ug_device.aurora_clk;
    let controllerRst = ug_device.aurora_rst;
    let isAuroraInRst <- isResetAsserted(clocked_by controllerClk, reset_by controllerRst);


    Bit#(16) handshakeWords[4] = {'hdead,'hbeef,'hcafe,'hfeed};

    Reg#(Bit#(10)) ccCycles  <- mkReg(maxBound, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(2)) handshakeRX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(2)) flitCount <-  mkReg(0, clocked_by(controllerClk), reset_by(controllerRst));    
    Reg#(Bool)    dropData <-  mkReg(True, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(2)) handshakeTX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    COUNTER#(TAdd#(1,TLog#(TDiv#(BufferSize,4)))) txCredits   <- mkLCounter(fromInteger(valueof(BufferSize)/4), clocked_by(controllerClk), reset_by(controllerRst)); 
    CrossingReg#(Bit#(16)) txCreditsCross <- mkNullCrossingReg(modelClock, fromInteger(valueof(BufferSize)/4), clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bool) creditUnderflow <- mkNullCrossingReg(modelClock, False, clocked_by controllerClk, reset_by controllerRst);


    COUNTER#(TAdd#(1,TLog#(TDiv#(BufferSize,4)))) rxCredits   <- mkLCounter(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    CrossingReg#(Bit#(16)) rxCreditsCross <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(16)) dataDrops <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFlowcontrol <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFlowcontrol <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
 
    rule creditCross; 
        rxCreditsCross <= zeroExtend(rxCredits.value());
        txCreditsCross <= zeroExtend(txCredits.value());
    endrule

    Reg#(Bool) handshakeRXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) handshakeTXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) ccLast <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 

    SyncFIFOCountIfc#(Bit#(63),TDiv#(BufferSize,4)) serdes_rxfifo <- mkSyncFIFOCount( controllerClk, controllerRst, clk);
    SyncFIFOCountIfc#(Bit#(63),TDiv#(BufferSize,4)) serdes_txfifo <- mkSyncFIFOCount( clk, rst, controllerClk);

    SyncFIFOCountIfc#(Bit#(16),2) txDebugBufferCrossing <- mkSyncFIFOCount( controllerClk, controllerRst, clk);
    let txDebugBuffer <- mkTriggeredStreamCaptureFIFOF(2048, clocked_by(controllerClk), reset_by(controllerRst));

    SyncFIFOCountIfc#(Bit#(16),2) rxDebugBufferCrossing <- mkSyncFIFOCount( controllerClk, controllerRst, clk);
    let rxDebugBuffer <- mkTriggeredStreamCaptureFIFOF(2048, clocked_by(controllerClk), reset_by(controllerRst));
    
    // need to make sure that flow control can come through
    let serdes_infifo <- mkSizedBRAMFIFOF(4*valueof(BufferSize), clocked_by controllerClk, reset_by controllerRst);


    // Clock compensation occurs periodically in the phy.  We need to
    // allow it to occur at least once before we attempt to send data.

    rule updateCCLast;
        ccLast <= ug_device.cc;
    endrule

    rule tickCC(ccCycles > 0 && ug_device.cc  && unpack(ug_device.channel_up) && !ccLast);
        ccCycles <= ccCycles - 1;
        $display("Ticking CC  %d", ccCycles);
    endrule

    // Send a set of known values across to the other side, as a synchronization step

    rule txHandshake (ccCycles == 0 && !handshakeTXDone);
        handshakeTX <= handshakeTX + 1;
        if(handshakeTX + 1 == 0)
        begin
            handshakeTXDone <= True;
        end

        ug_device.send(handshakeWords[handshakeTX]);
    endrule

    // This wire lets us check whether we ever drop data on receive.
    let rxFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);

    // Receive and check handshake values.

    rule rxHandshake (!handshakeRXDone);
        let data <- ug_device.receive;
        rxFires.send();
        Bool handshakeMatch = handshakeWords[handshakeRX] == data;
        if(handshakeMatch)
        begin
            handshakeRX <= handshakeRX + 1;
        end
        else 
        begin
            handshakeRX <= 0;
        end

        if(handshakeRX + 1 == 0 && handshakeMatch)
        begin
            $display("RX Handshake Done!");
            handshakeRXDone <= True;
        end
    endrule



    // Transmit side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - normal message
    // 11 - flow control credit
    // 10 - hearbeat

    MARSHALLER#(Bit#(16), Bit#(64)) marshaller <- mkSimpleMarshallerHighToLow(clocked_by(controllerClk), 
                                                                              reset_by(controllerRst));
    Reg#(Bit#(11)) heartbeat  <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst));

    rule beat;
        heartbeat <= heartbeat + 1;
    endrule

    rule txHeartbeat (handshakeTXDone && heartbeat == 0);
        marshaller.enq({2'b10,'hc001f00dd00d});
    endrule

    PulseWire transmittingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    PulseWire updatingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));

    rule txFC(handshakeTXDone && ((rxCredits.value() > fromInteger(valueof(HalfCredits)) && (!serdes_txfifo.dNotEmpty || txCredits.value() == 0)) || rxCredits.value() > fromInteger(valueof(ThreeFourthsCredits))));
        rxCredits.setC(0);
        marshaller.enq({2'b11,zeroExtend(rxCredits.value()),48'hdeadbeefcafe});
        $display("TX Sends Flowcontrol %h", rxCredits.value());
        txFlowcontrol <= txFlowcontrol + 1;
        transmittingCredits.send();
    endrule

    rule txData(handshakeTXDone && txCredits.value > 0 && !transmittingCredits);
        marshaller.enq({1'b0,serdes_txfifo.first});
        serdes_txfifo.deq;
	txCredits.downBy(1);
        $display("TX Sends Data %h, credits %d", serdes_txfifo.first, txCredits.value());
    endrule

    rule noCredit(txCredits.value == 0);
        $display("TX Has no credits");
    endrule

    rule txSend (handshakeTXDone);
        marshaller.deq;
        ug_device.send(marshaller.first);
        txDebugBuffer.fifof.enq(marshaller.first);
    endrule


    // Receive side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - normal message
    // 11 - flow control credit
    // 10 - hearbeat
    // The payload of the 1X message will be dropped - only the first flit contains useful information.
    // Credit updates are decoupled from the main processing pipeline by way of a FIFO.

    DEMARSHALLER#(Bit#(16), Bit#(64)) demarshaller <- mkSimpleDemarshallerHighToLow(clocked_by(controllerClk), 
                                                                                    reset_by(controllerRst));

    FIFO#(Bit#(TAdd#(1,TLog#(TDiv#(BufferSize,4))))) creditFIFO <- mkSizedFIFO(4,clocked_by(controllerClk),
                                                                                 reset_by(controllerRst));
 

    // use flit number to distinguish flow control. first flit is header.
    rule rxIntake (handshakeRXDone);  // We always need to receive
        let data <- ug_device.receive;
        rxFires.send();
        flitCount <= flitCount + 1;
        rxDebugBuffer.fifof.enq(data);
        if(flitCount == 0)
        begin
            if(data[15:14] == 2'b11)
            begin
	        // we got a flow control credit
                rxFlowcontrol <= rxFlowcontrol + 1;
                creditFIFO.enq(truncate(data));
                dropData <= True;
                $display("RX Got credits %d", data[14:0]);
            end          
            else if(data[15:14] == 2'b10)
            begin
                dropData <= True;
                $display("RX Got heartbeat");
            end          
            else
            begin
                dropData <= False;
                serdes_infifo.enq(data);
                $display("RX starts data %d", data);
            end
        end
        else if(!dropData)
        begin
            serdes_infifo.enq(data);
            $display("RX data %d", data);
        end
    endrule 

    rule drop(!rxFires && ug_device.receive_rdy());
        dataDrops <= dataDrops + 1;
    endrule 

    rule updateCredit;
        creditFIFO.deq;  
        $display("RX Updates Credits %d", creditFIFO.first());
        txCredits.upBy(truncate(creditFIFO.first()));
        // Bad news - the flow control protocol is broken :(
        if(zeroExtend(txCredits.value()) + creditFIFO.first() > fromInteger(valueof(TDiv#(BufferSize,4))))
        begin
            creditUnderflow <= True;
	    rxDebugBuffer.trigger();
	    txDebugBuffer.trigger();
	    $display("RX credit underflow");
            $finish;
        end
    endrule
    
    rule rxDemarsh;  
        serdes_infifo.deq();
        demarshaller.enq(serdes_infifo.first);
    endrule

    rule rxDone (handshakeRXDone && !transmittingCredits);   
        demarshaller.deq;
        rxCredits.upBy(1);
        serdes_rxfifo.enq(truncate(demarshaller.first()));
    endrule

    // These methods are used in debugging the flow control.  They are tied to
    // printfs in the aurora service layer. 

    mkConnection(toPut(txDebugBufferCrossing), toGet(txDebugBuffer.fifof));
    mkConnection(toPut(rxDebugBufferCrossing), toGet(rxDebugBuffer.fifof));

    rule sendUnderflow;
        ug_device.underflow(creditUnderflow, flitCount, zeroExtend(txCredits.value),  zeroExtend(rxCredits.value));       
    endrule


     
    interface AURORA_WIRES wires;
        method aurora_clk_p = ug_device.gtxq_p;
        method aurora_clk_n = ug_device.gtxq_n;

	method rxp_in = ug_device.rxp_in;
	method rxn_in = ug_device.rxn_in;
	method txp_out = ug_device.txp_out;
	method txn_out = ug_device.txn_out;
	interface Clock model_clk = clk;
        interface Reset model_rst = rst;
	interface Clock aurora_clk = ug_device.aurora_clk;
        interface Reset aurora_rst = ug_device.aurora_rst;
    endinterface
   
    interface AURORA_DRIVER driver;
        method write = serdes_txfifo.enq;

        method write_ready = serdes_txfifo.sNotFull();

        method deq = serdes_rxfifo.deq();

        method first = serdes_rxfifo.first();

        
        method channel_up = ug_device.channel_up;
        method lane_up = ug_device.lane_up;
        method hard_err = ug_device.hard_err;
        method soft_err = ug_device.soft_err;
        method rx_credit = rxCreditsCross.crossed();
        method credit_underflow = creditUnderflow.crossed();
        method tx_credit = txCreditsCross.crossed();
        method data_drops = dataDrops.crossed();
        method tx_fc = txFlowcontrol.crossed();
        method rx_fc = rxFlowcontrol.crossed();
        method rx_count = ug_device.rx_count;
        method tx_count = ug_device.tx_count;
        method error_count = ug_device.error_count;
        method rx_fifo_count = zeroExtend(pack(serdes_rxfifo.dCount));
        method tx_fifo_count = zeroExtend(pack(serdes_txfifo.sCount));
        interface Get rxDebug = toGet(rxDebugBufferCrossing);
        interface Get txDebug = toGet(txDebugBufferCrossing);
    endinterface
 
endmodule
