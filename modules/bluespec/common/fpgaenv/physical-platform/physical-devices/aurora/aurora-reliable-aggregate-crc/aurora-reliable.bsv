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

typedef 8 ParitySize;

typedef TSub#(TMul#(interface_words, TSub#(word_width,1)), ParitySize) AURORA_INTERFACE_WIDTH#(numeric type interface_words, numeric type word_width);

interface CRC#(numeric type poly_width, numeric type data_size);

    method ActionValue#(Bit#(TSub#(poly_width,1))) hash(Bit#(poly_width) poly, Bit#(data_size) bitsIn);

endinterface

// I wish this was polymorphic....

(* noinline *)
function Bit#(8) doHash(Bit#(8) initializer, Bit#(64) bitsIn);
    Bit#(9) poly = 'h183;

    function Bit#(8) oneStep(Bit#(1) bitIn, Bit#(8) rem_temp);
        Bit#(9) result = {rem_temp,bitIn};
        if(truncateLSB(rem_temp) == 1'b1) // grab top bit
        begin
            result = result ^ poly;
        end
        return truncate(result);
    endfunction

    Vector#(64,Bit#(1)) bitVec = unpack(bitsIn);
    return foldr(oneStep,initializer,bitVec);
endfunction



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
    method Bit#(32) error_count;
    method Bit#(32) rx_fifo_count;
    method Bit#(32) tx_fifo_count;
    method Bit#(16) data_drops;
    method Bit#(32) tx_frames;
    method Bit#(32) tx_frames_correct;
    method Bit#(32) rx_frames;
    method Bit#(32) rx_frames_correct;
    method Bit#(32) rx_frames_acked;
    method Bit#(32) timeouts;

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

module mkAURORA_FLOWCONTROL#(AURORA_SINGLE_DEVICE_UG#(width) ugDevice, NumTypeParam#(interface_words) interfaceWordsParam) 
    (AURORA_DEVICE#(interface_width))
    provisos(
             // provisos for protocol
             NumAlias#(ParitySize, parity_size),
             NumAlias#(32,frame_words),
             NumAlias#(2, max_frames),
             NumAlias#(8, sequence_numbers),
             Add#(1, parity_size, poly_width),
             NumAlias#(TMul#(frame_words, interface_words), frame_size), // Need to have an even number of words per transfer
             Add#(1,parity_size,poly_width), 
             Add#(width_parity_extra, parity_size, width),
             Mul#(frame_size, max_frames, total_credits),
             // provisos for data payload words
             Add#(data_size, 0, payload_size),
             Add#(1,payload_size,width), // We use one bit to encode the data payload
             Add#(1, data_size, width),
             // provisos related to in-band control
             Add#(TLog#(sequence_numbers), extra_control, control_payload),
             Add#(2,control_payload,width), // We use two bita to encode the control payload
             Add#(width_sequence_extra, TLog#(sequence_numbers), width),
             Add#(data_size_extra, TLog#(sequence_numbers), data_size),
             Add#(data_size_parity_extra, parity_size, data_size),  
             Add#(parity_size, control_data_size, control_payload),
             Add#(payload_ack_extra, TLog#(sequence_numbers), payload_size),
             Add#(control_parity_payload_extra, TLog#(sequence_numbers), control_data_size),
             Add#(TAdd#(1,parity_size), control_data_size, data_size),
             Add#(trunc_extra, TLog#(sequence_numbers), TSub#(width, 2)),  // This two comes from the definition of ack below
             Add#(TAdd#(2,parity_size), control_data_size, width),
             
             // interface provisos
             Add#(interface_width, parity_size, TMul#(data_size, interface_words)),
             Add#(frame_fragment_extra, TLog#(interface_words), TLog#(TMul#(frame_words, interface_words)))
    );

    let modelClock <- exposeCurrentClock();

    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();
    let isModelInRst <- isResetAsserted();
    let controllerClk = ugDevice.aurora_clk;
    let controllerRst = ugDevice.aurora_rst;
    let isAuroraInRst <- isResetAsserted(clocked_by controllerClk, reset_by controllerRst);

    //Bit#(poly_width) crc_poly = 'h89; // a 7 bit crc poly

    Reg#(Bit#(18)) ccCycles  <- mkReg(maxBound, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool)    frameErrorRX <-  mkReg(True, clocked_by(controllerClk), reset_by(controllerRst)); 

    CrossingReg#(Bit#(16)) dataDrops <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFrames <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFramesCorrect <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFramesAcked <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFrames <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFramesCorrect <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) timeouts <- mkNullCrossingReg(modelClock, 0, clocked_by controllerClk, reset_by controllerRst);


    Reg#(Bool) handshakeRXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst));  
    Reg#(Bool) handshakeTXDone <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 
    Reg#(Bool) ccLast <- mkReg(False, clocked_by(controllerClk), reset_by(controllerRst)); 

    SyncFIFOCountIfc#(Bit#(interface_width),8) serdesRxfifo <- mkSyncFIFOCount( controllerClk, controllerRst, clk);
    SyncFIFOCountIfc#(Bit#(interface_width),8) serdesTxfifo <- mkSyncFIFOCount( clk, rst, controllerClk);

    Reg#(Bit#(TLog#(frame_size))) framePositionRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(frame_size))) provisionalFramePositionRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(frame_size))) framePositionTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) provisionalSequenceNumberRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) sequenceNumberRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(interface_words)))  fragmentNumberRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(interface_words)))  fragmentNumberTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(TLog#(sequence_numbers))) sequenceNumberTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    RewindFIFOVariableCommitLevel#(Bit#(data_size),TMul#(max_frames, frame_size)) txDataRewindBuffer <- mkRewindFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);
    RewindFIFOVariableCommitLevel#(Bit#(TLog#(sequence_numbers)),max_frames) txSequenceRewindBuffer <- mkRewindFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(32)) frameTimeout <- mkSizedFIFOF(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);      
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberTX <- mkSizedFIFOF(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);      
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberRX <- mkSizedFIFOF(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackRX <- mkSizedFIFOF(4, clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) frameInProgress <- mkSizedFIFOF(1, clocked_by controllerClk, reset_by controllerRst); // Must be size 1.
    Reg#(Bit#(32)) timer <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);

    // need to make sure that flow control can come through
    PulseWire transmittingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    PulseWire updatingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    FIFOF#(Tuple2#(Bit#(1), Bit#(width))) serdesInfifo <- mkSizedBRAMFIFOF(valueof(total_credits), clocked_by controllerClk, reset_by controllerRst);
    MARSHALLER#(Bit#(data_size), Bit#(TAdd#(interface_width, parity_size))) marshaller <- mkSimpleMarshallerHighToLow(clocked_by(controllerClk), 

                                                                                                      reset_by(controllerRst));

    Bit#(parity_size) parityZeros = 0;
    let timeoutFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);
    let timeoutThreshold = 1000*`AURORA_INTERFACE_FREQ; // Timeout after us

    // need a concrete, large size to make bluespec happy.  truncateNP for the win!
    Bit#(32) ifcWords = fromInteger(valueof(interface_words));
    Bit#(32) frameSize = fromInteger(valueof(frame_size));

    rule timerCount;
        timer <= timer + 1;
    endrule    

    rule sequenceStuffer;
        txSequenceRewindBuffer.enq(sequenceNumberTX);
        sequenceNumberTX <= sequenceNumberTX + 1;
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin 
            $display("TX Sequence number going in rewind buffer"); 
        end
    endrule

    rule passRewind;
        txDataRewindBuffer.enq(marshaller.first);
        marshaller.deq;
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX Marsh: %h", marshaller.first); 
        end
    endrule

    // Clock compensation occurs periodically in the phy.  We need to
    // allow it to occur at least once before we attempt to send data.
    rule tickCC(ccCycles > 0 && ugDevice.cc  && unpack(ugDevice.channel_up));
        ccCycles <= ccCycles - 1;
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("Ticking CC  %d", ccCycles);
        end
    endrule


    rule crossDomain;
        marshaller.enq({serdesTxfifo.first, parityZeros});
        serdesTxfifo.deq;
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX Link: %h", serdesTxfifo.first);
        end
    endrule

    // Send a set of known values across to the other side, as a synchronization step

    // This wire lets us check whether we ever drop data on receive.
    let rxFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);

    // timeout wipes out the known world.
    rule timeout(abs(timer - frameTimeout.first) > timeoutThreshold);
        ackSequenceNumberRX.clear();
        frameTimeout.clear();
        frameInProgress.clear();
        txDataRewindBuffer.rewind();
        txSequenceRewindBuffer.rewind();
        timeoutFires.send;
        timeouts <= timeouts + 1;    
    endrule

    if(`AURORA_RELIABLE_DEBUG > 0) 
    begin  
        rule displayTimerStatus(timer[15:0] == 0);
            $display("Timer status: timeout present: %d timer %d timeout %d abs %d total timeouts: %d tx correct %d rx correct %d", frameTimeout.notEmpty, timer, frameTimeout.first, abs(timer - frameTimeout.first), timeouts, txFramesCorrect, rxFramesCorrect);
            $display("Check %d",abs(timer - frameTimeout.first) > timeoutThreshold);
            $display("frameTimeout %d frameInProgress %d", frameTimeout.notEmpty, frameInProgress.notEmpty);
        endrule
    end

    // Transmit side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - normal message
    // 11 - flow control credit
    // 10 - hearbeat
 
    Wire#(Bit#(parity_size)) initialWire <- mkWire(clocked_by(controllerClk), reset_by(controllerRst));
    PulseWire                mixHash     <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    RWire#(Bit#(width))      dataWire <- mkRWire(clocked_by(controllerClk), reset_by(controllerRst));

    rule txHeader(!transmittingCredits && ccCycles == 0 && ugDevice.transmit_rdy);
        Bit#(control_data_size) seqExtend = zeroExtend(txSequenceRewindBuffer.first);
        dataWire.wset({header, seqExtend, parityZeros});
        frameInProgress.enq(?);
        initialWire <= 0;
        mixHash.send();

        // reset fream state
        framePositionTX <= 0;
        fragmentNumberTX <= 0;
        txFrames <= txFrames + 1;

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX sending header");
        end

        // If we get corruption in a partial packet, it is possible 
        // for deadlocks to occur.  Thus we should also treat this as a
        // timeout.  This can lead to spurious retransmissions, but this 
        // is an edge case that can only occur on a low-traffic link.
        
        frameTimeout.enq(timer);
    endrule


    // since there's a timeout on acks we should transmit them quickly.
    rule txACK(ccCycles == 0 && ugDevice.transmit_rdy);
        ackSequenceNumberTX.deq();
        initialWire <= 0;
        Bit#(control_data_size) ackExtend = zeroExtend(ackSequenceNumberTX.first);
        dataWire.wset({ack, ackExtend, parityZeros});
        transmittingCredits.send;
        mixHash.send();

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX sending ack");
        end
    endrule

    rule txSend (!transmittingCredits && frameInProgress.notEmpty && ugDevice.transmit_rdy);
        txDataRewindBuffer.deq;
        dataWire.wset({payload, txDataRewindBuffer.first}); // we already added in the last zeros. 
        initialWire <= parityTX;

        if(fragmentNumberTX + 1 == truncateNP(ifcWords))
        begin
            fragmentNumberTX <= 0; 
            mixHash.send();
        end
        else 
        begin 
            fragmentNumberTX <= fragmentNumberTX + 1;
        end

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX: data pos %d / frag %d", framePositionTX, fragmentNumberTX);
        end
        
        if(framePositionTX + 1 == truncateNP(frameSize))
        begin
            // next up we should send the sequence number.
            frameInProgress.deq; 
            txSequenceRewindBuffer.deq;
            ackSequenceNumberRX.enq(txSequenceRewindBuffer.first);

            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("TX: Completes packet, enqueues ACK %d", txSequenceRewindBuffer.first);
            end
        end
        else 
        begin
            framePositionTX <= framePositionTX + 1;
        end 

    endrule

    // Bottom half of three above rules, actually does the transmission
    rule sendData(dataWire.wget matches tagged Valid .data);
        Bool isPayload = truncateLSB(data) == payload;
        Bool isHeader  = truncateLSB(data) == header;

        Bit#(parity_size) hashTX = doHash(initialWire, zeroExtendNP(data));
        if(isPayload || isHeader)
        begin
            parityTX <= hashTX;
        end

        // Some payload packets don't have a hash mixed in.
        let rawValue = {data|(mixHash?zeroExtend(hashTX):0)};

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("TX raw: %h", rawValue); 
            $display("TX initial %h, data %h ->  %h", initialWire, data, hashTX);
        end

        ugDevice.send(rawValue);
    endrule



    // Receive side.  We can send three different message classes, which are encoded using the high
    // order bits of the first flit.  
    // 0X - payload
    // 11 - frame ack
    // 10 - frame start 
    // The payload of the 1X message will be dropped - only the first flit contains useful information.
    // Credit updates are decoupled from the main processing pipeline by way of a FIFO.

    // Receive side consists of a two-stage protocol pipeline. The
    // first stage handles error checking and data aggregation. The 
    // second stage handles frame status and acknowledgement.

    DEMARSHALLER#(Bit#(data_size), Bit#(TAdd#(interface_width, parity_size))) demarshaller <- mkSimpleDemarshallerHighToLow(clocked_by(controllerClk), 
                                                                                    reset_by(controllerRst));
    PulseWire demarshClear <- mkPulseWire;

    // use flit number to distinguish flow control. first flit is header.
    rule rxIntake;  // We always need to receive
        let data <- ugDevice.receive;
        rxFires.send();
      
        // soft errors mean something bad happened in the encoding/on
        // the channel, so we'll just drop this data.
       
        serdesInfifo.enq(tuple2(ugDevice.soft_err,data)); 
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("RX raw: %h", data);
        end
       
    endrule 

    rule fullDeath (!ackRX.notFull || !serdesInfifo.notFull());
       $display("rxIntake blocks, and we die");
       $finish;
    endrule

    PulseWire dropFires <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));

    rule drop(!rxFires && ugDevice.receive_rdy());
        dataDrops <= dataDrops + 1;
        dropFires.send;
    endrule 

    rule handleAck(ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        // If this was an expected ack, take action
        if((ackSequenceNumberRX.first == ackRX.first))
        begin
            frameTimeout.deq;
            ackSequenceNumberRX.deq;
            txDataRewindBuffer.commit(tagged Valid truncateNP(frameSize));
            txSequenceRewindBuffer.commit(tagged Valid 1);
            txFramesCorrect <= txFramesCorrect + 1;
            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("RX ACK: %d", ackRX.first);
            end

        end
        else 
        begin
            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("RX ACK: (dropped) expected: %d got: %d", ackSequenceNumberRX.first(), ackRX.first);
            end
        end
    endrule
   
    // drop ack (we got a duplicate ack/some unexpected state)
    rule dropAck(!ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("RX ACK: (dropped) unexpected, got: %d", ackRX.first);
        end
    endrule

    rule framePositionAssertion(framePositionRX > truncateNP(frameSize));
        $display("Frame position is too large.  Die!");
        $finish;
    endrule

    rule rxDemarsh; // if we put data into the demarshaller, it must be known, correct data, or we will die.
        serdesInfifo.deq();
        match {.softErr, .rawFragment} = serdesInfifo.first;     

        // Although we split the data payload into data and parity pieces, in reality, only for the 
        // last part of a demarshalled message will the actual parity bits be included. 

        Tuple2#(Bit#(1), Bit#(data_size)) fragment = unpack(rawFragment);
        match {.ctrl, .data} = fragment;

        Tuple3#(Bit#(2),Bit#(control_data_size),Bit#(parity_size)) ctrlFragment = unpack(rawFragment);
        match {.ctrlHeader, .ctrlPayload, .hashExpected} = ctrlFragment;

        Bool isPayload = ctrl == payload;
        Bool isAck = truncateLSB(rawFragment) == ack;
        Bool isHeader = truncateLSB(rawFragment) == header;

        // Since we have cleverly aligned the packets, all hash computations are the same.
        // Need to fix up this calculation

        Bit#(parity_size) hashSalt = (isPayload)?parityRX:0;
        Bit#(parity_size) tailBits = (isPayload)?hashExpected:0;
        Bit#(parity_size) hashRX = doHash(hashSalt, zeroExtendNP(rawFragment));
      
        //Only check CRC at the end of a set of fragments
        Bool notCorrupt = (hashRX == 0 || (isPayload && (fragmentNumberRX + 1 != truncateNP(ifcWords)))) && softErr == 0;

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("**************");
            $display("RX Hashes(parityRX %h): %h, %h = %h/%h (corrupt: %d)", parityRX, hashSalt, rawFragment, hashRX, hashExpected, !notCorrupt);
            $display("Fragment isPayload: %h isAck: %h, isHeader:%h", isPayload, isAck, isHeader);
            $display("RX Status: pPos %d pSeq %d pos %d seq %d frameErrorRX %d", provisionalFramePositionRX, provisionalSequenceNumberRX, framePositionRX, sequenceNumberRX, frameErrorRX);
        end

        if(isPayload)
        begin

            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("Handle payload");
            end 

            // The issue here is that acks may get dropped. So we need to ack every correct packet.
            // However, we can't spuriously ack future packets.  To handle this issue, we need to have a few 
            // forbidden packets. 
            
            provisionalFramePositionRX <= provisionalFramePositionRX + 1;
            // only enq if 1) hash matches 2) no previous errors in the frame 3) we haven't enqueued this data already
            // (i.e.) as part of a correct partial frames
            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                 $display("RX Data: pos: %d hashExpected: %h hashRX: %h, data: %h", provisionalFramePositionRX, hashExpected, hashRX, serdesInfifo.first);         
            end

            if(fragmentNumberRX + 1 == truncateNP(ifcWords))
            begin
                fragmentNumberRX <= 0;
                parityRX <= hashExpected; 
            end
            else 
            begin
                fragmentNumberRX <= fragmentNumberRX + 1;
                parityRX <= hashRX;  
            end
           
            if(notCorrupt && !frameErrorRX) 
            begin
                // If we haven't seen this data before and we don't have an error, send it to the upper level. 
                if(provisionalFramePositionRX == framePositionRX && provisionalSequenceNumberRX == sequenceNumberRX)
                begin
                    demarshaller.enq(data);

                    if(framePositionRX + 1 == truncateNP(frameSize)) // frame_size must be a power of two
                    begin
                        // next up we should send the sequence number.
                        if(`AURORA_RELIABLE_DEBUG > 0) 
                        begin  
                            $display("RX: Packet Complete");
                        end

                        frameErrorRX <= True; // We need to see a header before commencing data
                        sequenceNumberRX <= sequenceNumberRX + 1; // we completed a packet
                        rxFramesCorrect <= rxFramesCorrect + 1;
                        framePositionRX <= 0; // reset true frame position on completion                           
                    end
                    else
                    begin
                        framePositionRX <= framePositionRX + 1;                           
                    end

                    if(`AURORA_RELIABLE_DEBUG > 0) 
                    begin  
                        $display("RX Marsh: %h", data);
                    end
 
                end
                else
                begin 
                    if(`AURORA_RELIABLE_DEBUG > 0) 
                    begin  
                        $display("RX Marsh: (repeat) %h", data);
                    end
                end
                // If we got a frame without error, then we should send an ack.  
                if(provisionalFramePositionRX + 1 == truncateNP(frameSize))
                begin
                    if(`AURORA_RELIABLE_DEBUG > 0) 
                    begin  
                        $display("RX Sending ACK");
                    end

                    // If we got the last data correctly send an ack.
                    rxFramesAcked <= rxFramesAcked + 1;
                    ackSequenceNumberTX.enq(provisionalSequenceNumberRX);
                end
            end

            // if we are corrupt, we should shoot down whatever is in the demarshaller.  In doing this, 
            // we must also adjust the frame count.
            else if(!notCorrupt && !frameErrorRX)
            begin

                if(`AURORA_RELIABLE_DEBUG > 0) 
                begin  
                    $display("RX Marsh: (drop) %h", data);
                end

                frameErrorRX <= True;  
                // Just in case the previous frame is still sitting in the buffer
                // We need to clear because we do not know what portion of the 
                // message was incorrect. We should only do this if we are handling 
                // expected sequence number 
                if(provisionalFramePositionRX == framePositionRX && provisionalSequenceNumberRX == sequenceNumberRX)
                begin
                    if(fragmentNumberRX != 0)
                    begin
                        demarshaller.clear();
                    end
 
                    framePositionRX <= framePositionRX - zeroExtend(fragmentNumberRX);  
                end             
            end

        end
        else if(isHeader)
        begin

            Bit#(TLog#(sequence_numbers)) headerSequence = truncate(ctrlPayload);
            $display("Handle header");
            rxFrames <= rxFrames + 1;
            // getting a header should cause us to reset our counters. but we should do this at the higher level.
            provisionalFramePositionRX <= 0;
            // did we get the right sequence number?  Since acks may be dropped at the transmitter, 
            // we have a set of frame that we will acknowledge.  Future frames will not be acknowledged.
            // to deal with wrap around, we use an enlarged frame space.  The secondor clause handles the wrap case.
            
            Bit#(1) headerTop = truncateLSB(headerSequence);
	    Bit#(1) seqTop = truncateLSB(sequenceNumberRX);
            
            // Second clause handles the wrap-around case, where the leading 0 packets are younger than the leading 1 packets 
            Bool frameErrorNext = (sequenceNumberRX < truncate(headerSequence) && 
                                       !(headerTop == 1 && (sequenceNumberRX < fromInteger(valueof(max_frames))))) || 
                                  (seqTop == 1 && ((headerSequence < fromInteger(valueof(max_frames))))) ||
                                   !notCorrupt;
            
            frameErrorRX <= frameErrorNext;
            provisionalSequenceNumberRX <= headerSequence; 
            fragmentNumberRX <= 0;
            
            // If we got interrupted in the middle of the correct
            // packet, then we need to reset the demarshaller, since we
            // will have no way to check the data already enqueued.
            if(provisionalFramePositionRX == framePositionRX && provisionalSequenceNumberRX == sequenceNumberRX && !frameErrorRX)
            begin

                if(fragmentNumberRX != 0)
                begin
                    demarshaller.clear();
                end
 
                framePositionRX <= framePositionRX - zeroExtend(fragmentNumberRX);  
            end             
         
            parityRX <= hashExpected;
        
            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("RX Header: seq_no: %d", headerSequence);
                $display("frame error %d, seq clause %d, wrap clause %d", frameErrorNext, (sequenceNumberRX < truncate(headerSequence)),  (seqTop == 1 && ((headerSequence < fromInteger(valueof(max_frames))))));
            end
        end
        else if(isAck)
        begin
            if(`AURORA_RELIABLE_DEBUG > 0) 
            begin  
                $display("RX Handle ACK");
            end

            if(notCorrupt)
            begin
                ackRX.enq(truncate(ctrlPayload));
            end
        end

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("**************");
        end
    endrule


    rule rxDone;   
        demarshaller.deq;
       
        serdesRxfifo.enq(truncateLSB(demarshaller.first()));

        if(`AURORA_RELIABLE_DEBUG > 0) 
        begin  
            $display("RX Link: %h", demarshaller.first);
        end
    endrule


    if(`AURORA_RELIABLE_DEBUG > 0) 
    begin
        rule sendUnderflow;
            ugDevice.underflow(frameErrorRX, zeroExtend({pack(dropFires),pack(timeoutFires)}),  zeroExtend(txSequenceRewindBuffer.first),  zeroExtend(sequenceNumberRX));
        endrule
    end

 
    interface AURORA_WIRES wires;

	method rxp_in = ugDevice.rxp_in;
	method rxn_in = ugDevice.rxn_in;
	method txp_out = ugDevice.txp_out;
	method txn_out = ugDevice.txn_out;
	interface Clock model_clk = clk;
        interface Reset model_rst = rst;
	interface Clock aurora_clk = ugDevice.aurora_clk;
        interface Reset aurora_rst = ugDevice.aurora_rst;

    endinterface
   
    interface AURORA_DRIVER driver;

        method write = serdesTxfifo.enq;

        method write_ready = serdesTxfifo.sNotFull();

        method deq = serdesRxfifo.deq();

        method first = serdesRxfifo.first();
        
        method channel_up = ugDevice.channel_up;
        method lane_up = ugDevice.lane_up;
        method hard_err = ugDevice.hard_err;
        method soft_err = ugDevice.soft_err;
        method data_drops = dataDrops.crossed();
        method rx_count = ugDevice.rx_count;
        method tx_count = ugDevice.tx_count;
        method error_count = ugDevice.error_count;
        method rx_frames = rxFrames.crossed();
        method rx_frames_correct = rxFramesCorrect.crossed();
        method rx_frames_acked = rxFramesAcked.crossed();
        method tx_frames = txFrames.crossed();
        method tx_frames_correct = txFramesCorrect.crossed();
        method timeouts = timeouts.crossed();
    endinterface
 
endmodule
