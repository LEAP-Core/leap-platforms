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
`include "awb/provides/aurora_driver_params.bsh"

    // 0X - normal message
    // 11 - frame ack
    // 10 - frame start

// definitions of fragment headers
Bit#(1) payload = 1'b0;
Bit#(2) ack     = 2'b11;
Bit#(2) header   = 2'b10;


interface AURORA_WIRES;
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
// Notice that we do a N to 1 vectorization here.  This is to exploit the high bandwidth of the link relative to our
// clock frequency.  Ideally, we would choose vectorization intelligently based on MODEL_CLOCK_FREQ and the link
// bandwidth, but I don't have time for that now, and making it a constant gets most of the performance. 
interface AURORA_DRIVER#(numeric type interface_width);
    method Action                 write(Bit#(interface_width) tx_word); // txusrclk 
    method Bool                   write_ready(); // txusrclk 
    method Action                 deq(); // rxusrclk0     
    method Bit#(interface_width)   first(); // rxusrclk0     


    // Debugging interface
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bool     credit_underflow;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) heartbeat_count;
    method Bit#(32) error_count;
    method Bit#(32) rx_fifo_count;
    method Bit#(32) tx_fifo_count;
    method Bit#(16) tx_credit;
    method Bit#(16) rx_credit;
    method Bit#(16) data_drops;
    method Bit#(32) tx_fc;
    method Bit#(32) rx_fc;

endinterface

interface AURORA_DEVICE#(numeric type width);
    (* prefix = "" *)      
    interface AURORA_WIRES wires;
    interface AURORA_DRIVER#(width) driver;
endinterface      

// Parameterizations for the aurora flow control interface.
// Eventually, these should be codified as first order parameters.
// Also the width of the interface should automatically adjust based on 
// clock ratios.

module mkAURORA_FLOWCONTROL#(AURORA_SINGLE_DEVICE_UG#(width) ug_device, NumTypeParam#(interface_words) interfaceWordsParam) 
    (AURORA_DEVICE#(interface_width))
    provisos(
             // provisos for protocol
             NumAlias#(7, parity_size),
             NumAlias#(64, frame_size),
             NumAlias#(2, max_frames),
             NumAlias#(8, sequence_numbers),
             Add#(1,parity_size,poly_width),
             Mul#(frame_size, max_frames, total_credits),
             Add#(0,TExp#(TLog#(frame_size)),frame_size),
             // provisos for data payload words
             Add#(1, payload_width, width),	
             Add#(data_size,parity_size,payload_size),
             Add#(1,payload_size,width), // We use one bit to encode the data payload
             // provisos related to in-band control
             Add#(TLog#(sequence_numbers), extra_control, control_payload),
             Add#(2,control_payload,width), // We use two bita to encode the control payload
             Add#(width_sequence_extra, TLog#(sequence_numbers), width),
             Add#(data_size_extra, TLog#(sequence_numbers), data_size),
             Add#(parity_size, control_parity_extra, control_payload),
             Add#(payload_ack_extra, TLog#(sequence_numbers), payload_size),
             Add#(control_parity_payload_extra, TLog#(sequence_numbers), control_parity_extra),
             Add#(trunc_extra, TLog#(sequence_numbers), TSub#(width, 2)),  // This two comes from the definition of ack below
             // interface provisos
             Mul#(data_size,interface_words,interface_width)
    );

    Bit#(8) crc_poly = 'h89; // a 7 bit crc poly

    // do a combinational crc.    
    // use payload_size so as to chain in some bits from the previous word
    function Bit#(parity_size) hash(Bit#(poly_width) poly, Bit#(payload_size) bitsIn);
     /*
        Bit#(parity_size) poly_trunc = truncateLSB(reverseBits(poly));

        function Bit#(payload_size) oneStep(Bit#(payload_size) rem_temp, Bit#(1) bitIn);
            Bit#(payload_size) result = rem_temp >> 1;
            if(bitIn==1) // grab top bit
            begin
                result = (rem_temp >> 1) ^ zeroExtend(poly_trunc);
            end
            return result;
        endfunction 

        Vector#(payload_size,Bit#(1)) bitVec = unpack(bitsIn);
        return truncate(foldl(oneStep,0,bitVec));*/
        let topBits = truncateLSB(bitsIn);
        return topBits + 1; 
    endfunction



    let modelClock <- exposeCurrentClock();

    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();
    let isModelInRst <- isResetAsserted();
    let controllerClk = ug_device.aurora_clk;
    let controllerRst = ug_device.aurora_rst;
    let isAuroraInRst <- isResetAsserted(clocked_by controllerClk, reset_by controllerRst);



    Reg#(Bit#(10)) ccCycles  <- mkReg(maxBound, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(2)) handshakeRX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(TAdd#(1,TLog#(interface_words)))) flitCountRX <-  mkReg(0, clocked_by(controllerClk), reset_by(controllerRst));    
    Reg#(Bit#(TAdd#(1,TLog#(interface_words)))) flitCountTX <-  mkReg(0, clocked_by(controllerClk), reset_by(controllerRst));    
    Reg#(Bool)    frameErrorRX <-  mkReg(True, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(2)) handshakeTX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 


    COUNTER#(TAdd#(1,TLog#(total_credits))) rxCredits   <- mkLCounter(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    CrossingReg#(Bit#(16)) rxCreditsCross <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(16)) dataDrops <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFlowcontrol <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFlowcontrol <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) heartbeatCount <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
 

    Reg#(Bool) handshakeRXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst));  
    Reg#(Bit#(5)) heartbeatTX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(5)) heartbeatRX <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bit#(5)) heartbeatConsecutive <- mkReg(0, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) handshakeTXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) heartbeatFirst <- mkReg(True, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) ccLast <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 

    SyncFIFOCountIfc#(Bit#(interface_width),8) serdes_rxfifo <- mkSyncFIFOCount( controllerClk, controllerRst, clk);
    SyncFIFOCountIfc#(Bit#(interface_width),8) serdes_txfifo <- mkSyncFIFOCount( clk, rst, controllerClk);


    Reg#(Bit#(TLog#(frame_size))) framePositionRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(frame_size))) provisionalFramePositionRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(frame_size))) framePositionTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) provisionalSequenceNumberRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) sequenceNumberRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) sequenceNumberTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    RewindFIFOVariableCommitLevel#(Bit#(data_size),frame_size) tx_data_rewind_buffer <- mkRewindFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);
    RewindFIFOVariableCommitLevel#(Bit#(TLog#(sequence_numbers)),max_frames) tx_sequence_rewind_buffer <- mkRewindFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);
    FIFO#(Bit#(32)) frame_timeout <- mkSizedFIFO(valueof(max_frames));      
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberTX <- mkSizedFIFOF(valueof(max_frames));      
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberRX <- mkSizedFIFOF(valueof(max_frames));
    FIFOF#(Bit#(TSub#(width,2))) ackRX <- mkSizedFIFOF(4);
    FIFOF#(Bit#(TLog#(sequence_numbers))) frame_in_progress <- mkSizedFIFOF(1); // Must be size 1.
    Reg#(Bit#(32)) timer <- mkReg(0);

    // need to make sure that flow control can come through
    PulseWire transmittingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    PulseWire updatingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    FIFOF#(Bit#(width)) serdes_infifo <- mkSizedBRAMFIFOF(valueof(total_credits), clocked_by controllerClk, reset_by controllerRst);
    MARSHALLER#(Bit#(data_size), Bit#(interface_width)) marshaller <- mkSimpleMarshallerHighToLow(clocked_by(controllerClk), 
                                                                                                      reset_by(controllerRst));

    let timeoutThreshold = 200*`AURORA_INTERFACE_FREQ;

    rule timerCount;
        timer <= timer + 1;
    endrule    

    rule sequenceStuff;
        tx_sequence_rewind_buffer.enq(sequenceNumberTX);
        sequenceNumberTX <= sequenceNumberTX + 1; 
        $display("TX Sequence number going in rewind buffer"); 
    endrule

    rule passRewind;
        tx_data_rewind_buffer.enq(marshaller.first);
        marshaller.deq;
        $display("TX Marsh: %h", marshaller.first); 
    endrule

    // Clock compensation occurs periodically in the phy.  We need to
    // allow it to occur at least once before we attempt to send data.
    rule tickCC(ccCycles > 0 && ug_device.cc  && unpack(ug_device.channel_up));
        ccCycles <= ccCycles - 1;
        $display("Ticking CC  %d", ccCycles);
    endrule

    // Send a set of known values across to the other side, as a synchronization step

    // This wire lets us check whether we ever drop data on receive.
    let rxFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);

    // Receive and check handshake values.

    // Transmit side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - normal message
    // 11 - flow control credit
    // 10 - hearbeat


    rule txHeader(!transmittingCredits && ccCycles == 0);
        Bit#(width) header_flit = {header,zeroExtend(tx_sequence_rewind_buffer.first)};
        ug_device.send(header_flit);
        frame_in_progress.enq(?);
        // reset fream state
        framePositionTX <= 0;
        parityTX <= 0;
        $display("TX header: %d", tx_sequence_rewind_buffer.first);
        $display("TX raw: %h", header_flit); 
    endrule


    // since there's a timeout on acks we should transmit them quickly.
    rule txFC;
        ackSequenceNumberTX.deq();
        let hashAck =  hash(crc_poly, zeroExtend(ackSequenceNumberTX.first)); // we could use the parityRX, since there is a concept of stream here. 
        Bit#(width) creditWord = {ack,hashAck,zeroExtend(ackSequenceNumberTX.first)};
        ug_device.send(creditWord);
        txFlowcontrol <= txFlowcontrol + 1;
        transmittingCredits.send;
        $display("TX raw: %h", creditWord); 
        $display("TX ACK: %d", ackSequenceNumberTX.first);
    endrule

    rule crossDomain;
        marshaller.enq(serdes_txfifo.first);
        serdes_txfifo.deq;
        $display("TX Link: %h", serdes_txfifo.first);
    endrule


    rule txSend (!transmittingCredits && frame_in_progress.notEmpty);
        tx_data_rewind_buffer.deq;
        Bit#(parity_size) parity = hash(crc_poly, {parityTX, tx_data_rewind_buffer.first});
        parityTX <= parity;
        let txRaw = {payload, parity, tx_data_rewind_buffer.first};
        ug_device.send(txRaw);
        $display("TX raw: %h", txRaw); 
        $display("TX Data: pos: %d data: %h",  framePositionTX , pack(txRaw) );
        if(framePositionTX + 1 == 0) // frame size must be a power of two
        begin
            // next up we should send the sequence number.
            frame_in_progress.deq; 
            frame_timeout.enq(timer);
            tx_sequence_rewind_buffer.deq;
            ackSequenceNumberRX.enq(tx_sequence_rewind_buffer.first);
        end
        else 
        begin
            framePositionTX <= framePositionTX + 1;
        end 
    endrule

    // timeout wipes out the known world.
    rule timeout(abs(timer - frame_timeout.first) > timeoutThreshold);
        frame_timeout.clear();
        ackSequenceNumberRX.clear();
        frame_in_progress.clear();
        tx_data_rewind_buffer.rewind();
        tx_sequence_rewind_buffer.rewind();
        $display("TX Timeout: %d", ackSequenceNumberRX.first);
    endrule

    // Receive side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - normal message
    // 11 - frame ack
    // 10 - frame start 
    // The payload of the 1X message will be dropped - only the first flit contains useful information.
    // Credit updates are decoupled from the main processing pipeline by way of a FIFO.

    // Receive side consists of a two-stage protocol pipeline. The
    // first stage handles error checking and data aggregation. The 
    // second stage handles frame status and acknowledgement.

    DEMARSHALLER#(Bit#(data_size), Bit#(interface_width)) demarshaller <- mkSimpleDemarshallerHighToLow(clocked_by(controllerClk), 
                                                                                    reset_by(controllerRst));

    FIFO#(Bit#(TAdd#(1,TLog#(total_credits)))) creditFIFO <- mkSizedFIFO(4,clocked_by(controllerClk),
                                                                                 reset_by(controllerRst));
 

    // use flit number to distinguish flow control. first flit is header.
    rule rxIntake;  // We always need to receive
        let data <- ug_device.receive;
        rxFires.send();
        $display("RX raw: %h", data);
        if(truncateLSB(data) == payload)
        begin
            serdes_infifo.enq(data); 
        end
        else if(truncateLSB(data) == header)
        begin
          // getting a header should cause us to reset our counters. but we should do this at the higher level.
            serdes_infifo.enq(data); 
        end          
        else if(truncateLSB(data) == ack)
        begin     
            ackRX.enq(truncate(data));
        end
    endrule 

    rule fullDeath (!ackRX.notFull || !serdes_infifo.notFull());
       $display("rxIntake blocks, and we die");
       $finish;
    endrule


    rule drop(!rxFires && ug_device.receive_rdy());
        dataDrops <= dataDrops + 1;
    endrule 

    rule handleAck(ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        let hashExpect = truncateLSB(ackRX.first);        
        let hashAck =  hash(crc_poly, zeroExtend(ackSequenceNumberTX.first)); // we could use the parityRX, since there is a concept of stream here. 
        // If this was an expected ack, take action
        if((ackSequenceNumberRX.first == truncate(ackRX.first)) && (hashAck == hashExpect))
        begin
            $display("RX ACK: %d", ackRX.first);
            frame_timeout.deq;
            ackSequenceNumberRX.deq;
            tx_data_rewind_buffer.commit(tagged Valid fromInteger(valueof(frame_size)));
            tx_sequence_rewind_buffer.commit(tagged Valid 1);
        end
        else 
        begin
            $display("RX ACK: (dropped) expected: %d got: %d", ackSequenceNumberRX.first(), ackRX.first);
        end
    endrule
   
    // drop ack (we got a duplicate ack/some unexpected state)
    rule dropAck(!ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        $display("RX ACK: (dropped) unexpected, got: %d", ackRX.first);
    endrule

    rule rxDemarsh; // if we put data into the demarshaller, it must be known, correct data, or we will die.
        serdes_infifo.deq();
     
        Tuple3#(Bit#(1), Bit#(parity_size), Bit#(data_size)) fragment = unpack(serdes_infifo.first);

        match {.header, .hashExpected, .data} = fragment;

        if(header == payload)
        begin
            // The issue here is that acks may get dropped. So we need to ack every correct packet.
            // However, we can't spuriously ack future packets.  To handle this issue, we need to have a few 
            // forbidden packets. 

            let hashNext =  hash(crc_poly, {parityRX, data});
            parityRX <= hashNext;
            provisionalFramePositionRX <= provisionalFramePositionRX + 1;
            // only enq if 1) hash matches 2) no previous errors in the frame 3) we haven't enqueued this data already
            // (i.e.) as part of a correct partial frames
            $display("RX Data: pos: %d hash: %h hashExpect: %h, data: %h", provisionalFramePositionRX, hashNext, hashExpected, serdes_infifo.first);
            $display("RX Nohash: %h", data);
            $display("RX Status: pPos %d pSeq %d pos %d seq %d frameErrorRX %d", provisionalFramePositionRX, provisionalSequenceNumberRX, framePositionRX, sequenceNumberRX, frameErrorRX);
            $display("RX Wide: %h", serdes_infifo.first);

            // XXX remove for reliability tests
            //if(provisionalFramePositionRX != framePositionRX)
            //begin
            //    $display("Positions not correct.");
            //    $finish;
            //end

            if(hashExpected == hashNext && !frameErrorRX) 
            begin
                // If we haven't seen this data before and we don't have an error, send it to the upper level. 
                if(provisionalFramePositionRX == framePositionRX && provisionalSequenceNumberRX == sequenceNumberRX)
                begin
                    demarshaller.enq(data);
                    $display("RX Marsh: %h", data);
                    if(framePositionRX + 1 == 0) // frame_size must be a power of two
                    begin
                        // next up we should send the sequence number.
                        frameErrorRX <= True; // We need to see a header before commencing data
                        sequenceNumberRX <= sequenceNumberRX + 1; // we completed a packet
                    end
                  
                    
                    framePositionRX <= framePositionRX + 1;                           
                end
                // If we got a frame without error, then we should send an ack.  
                if(provisionalFramePositionRX + 1 == 0)  // frame_size must be a power of two
                begin
                   // If we got the last data correctly send an ack.
                   ackSequenceNumberTX.enq(provisionalSequenceNumberRX);
                end
            end
            else 
            begin

                $display("RX Marsh: (drop) %h", data);
                frameErrorRX <= True;
            end
        end
        else // since acks went away we have only this leg.
        begin
            $display("RX Header: seq_no: %d", data);
            // getting a header should cause us to reset our counters. but we should do this at the higher level.
            provisionalFramePositionRX <= 0;
            // did we get the right sequence number?  Since acks may be dropped at the transmitter, 
            // we have a set of frame that we will acknowledge.  Future frames will not be acknowledged.
            // to deal with wrap around, we use an enlarged frame space.  The secondor clause handles the wrap case.
            Bit#(TLog#(sequence_numbers)) header_sequence = truncate(data);
            Bit#(1) header_top = truncateLSB(header_sequence);
	    Bit#(1) seq_top = truncateLSB(sequenceNumberRX);

            // Second clause handles the wrap-around case, where the leading 0 packets are younger than the leading 1 packets 
            Bool frameErrorNext = (sequenceNumberRX < truncate(header_sequence)) || (seq_top == 1 && ((header_sequence < fromInteger(valueof(max_frames)))));
            $display("frame error %d, seq clause %d, wrap clause %d", frameErrorNext, (sequenceNumberRX < truncate(header_sequence)),  (seq_top == 1 && ((header_sequence < fromInteger(valueof(max_frames))))));
            frameErrorRX <= frameErrorNext;
            provisionalSequenceNumberRX <= header_sequence; 
            parityRX <= 0;
        end
    endrule

    rule rxDone;   
        demarshaller.deq;
        serdes_rxfifo.enq(truncate(demarshaller.first()));
        $display("RX Link: %h", demarshaller.first);
    endrule

     
    interface AURORA_WIRES wires;

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
        method rx_credit = ?;
        method credit_underflow = ?;//creditUnderflow.crossed();
        method tx_credit = ?;
        method data_drops = dataDrops.crossed();
        method tx_fc = txFlowcontrol.crossed();
        method rx_fc = rxFlowcontrol.crossed();
        method heartbeat_count = heartbeatCount.crossed();
        method rx_count = ug_device.rx_count;
        method tx_count = ug_device.tx_count;
        method error_count = ug_device.error_count;
        method rx_fifo_count = zeroExtend(pack(serdes_rxfifo.dCount));
        method tx_fifo_count = zeroExtend(pack(serdes_txfifo.sCount));
    endinterface
 
endmodule
