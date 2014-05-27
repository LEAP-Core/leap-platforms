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

//
// Reliability layer for serial communication.  Compute a CRC on each
// packet.  Packets arriving with incorrect checksums will be retransmitted.
//

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
`include "awb/provides/aurora_common.bsh"
`include "awb/provides/aurora_driver_params.bsh"


//
// Definitions of fragment headers:
//   0X - normal message
//   11 - frame ack
//   10 - frame start
Bit#(1) payload = 1'b0;
Bit#(2) ack     = 2'b11;
Bit#(2) header  = 2'b10;

typedef 8 ParitySize;

typedef TMul#(interface_words, TSub#(word_width, TAdd#(1, ParitySize)))
    AURORA_INTERFACE_WIDTH#(numeric type interface_words, numeric type word_width);

//
// AURORA_DRIVER --
//   Guarded interface.  Notice that we do a N to 1 vectorization here.  This
//   is to exploit the high bandwidth of the link relative to our clock
//   frequency.  Ideally, we would choose vectorization intelligently based on
//   MODEL_CLOCK_FREQ and the link bandwidth.  Making it a constant gets most
//   of the performance.
//
interface AURORA_DRIVER#(numeric type interface_width);
    method Action                write(Bit#(interface_width) tx_word);
    method Bool                  write_ready();
    method Action                deq();
    method Bit#(interface_width) first();

    // Debugging interface
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;
    method Bit#(16) data_drops;
    method Bit#(32) rx_frames;
    method Bit#(32) rx_frames_correct;
    method Bit#(32) rx_frames_acked;
    method Bit#(32) tx_frames;
    method Bit#(32) tx_frames_correct;
    method Bit#(32) timeouts;
endinterface

interface AURORA_DEVICE#(numeric type width);
    (* prefix = "" *)      
    interface AURORA_WIRES wires;
    interface AURORA_DRIVER#(width) driver;
endinterface      


//
// Parameterizations for the aurora flow control interface.
// Eventually, these should be codified as first order parameters.
// Also the width of the interface should automatically be adjusted based
// on clock ratios.
//
module mkAURORA_FLOWCONTROL#(AURORA_SINGLE_DEVICE_UG#(width) ugDevice,
                             NumTypeParam#(interface_words) interfaceWordsParam)
    // Interface:
    (AURORA_DEVICE#(interface_width))
    provisos(
             // provisos for protocol
             NumAlias#(ParitySize, parity_size),
             Add#(1, parity_size, poly_width),
             NumAlias#(128, frame_size),
             NumAlias#(2, max_frames),
             NumAlias#(8, sequence_numbers),
             Add#(1, parity_size, poly_width),
             Mul#(frame_size, max_frames, total_credits),
             Add#(0, TExp#(TLog#(frame_size)), frame_size),
             // provisos for data payload words
             Add#(1, payload_width, width),
             Add#(data_size, parity_size, payload_size),
             // We use one bit to encode the data payload
             Add#(1, payload_size, width),
             Add#(TAdd#(1, parity_size), data_size, width),
             // provisos related to in-band control
             Add#(TLog#(sequence_numbers), extra_control, control_payload),
             // We use two bita to encode the control payload
             Add#(2, control_payload, width),
             Add#(width_sequence_extra, TLog#(sequence_numbers), width),
             Add#(data_size_extra, TLog#(sequence_numbers), data_size),
             Add#(parity_size, control_data_size, control_payload),
             Add#(payload_ack_extra, TLog#(sequence_numbers), payload_size),
             Add#(control_parity_payload_extra, TLog#(sequence_numbers), control_data_size),
             Add#(1, control_data_size, data_size),
             // This two comes from the definition of ack below
             Add#(trunc_extra, TLog#(sequence_numbers), TSub#(width, 2)),
             Add#(TAdd#(2, parity_size), control_data_size, width),
             // interface provisos
             Mul#(data_size, interface_words, interface_width)
    );

    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();
    let isModelInRst <- isResetAsserted();
    let controllerClk = ugDevice.aurora_clk;
    let controllerRst = ugDevice.aurora_rst;
    let isAuroraInRst <- isResetAsserted(clocked_by controllerClk, reset_by controllerRst);

    Reg#(Bit#(3)) ccCycles  <- mkReg(maxBound, clocked_by(controllerClk), reset_by(controllerRst));
    Reg#(Bool)    frameErrorRX <-  mkReg(True, clocked_by(controllerClk), reset_by(controllerRst));

    CrossingReg#(Bit#(16)) dataDrops <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFrames <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFramesCorrect <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) rxFramesAcked <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFrames <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) txFramesCorrect <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);
    CrossingReg#(Bit#(32)) timeouts <- mkNullCrossingReg(clk, 0, clocked_by controllerClk, reset_by controllerRst);

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
    Reg#(Bit#(TLog#(sequence_numbers))) sequenceNumberTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityRX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);
    Reg#(Bit#(parity_size)) parityTX <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);

    RewindFIFOVariableCommitLevel#(Bit#(data_size),
                                   TMul#(max_frames, frame_size))
        txDataRewindBuffer <- mkRewindBRAMFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);
    RewindFIFOVariableCommitLevel#(Bit#(TLog#(sequence_numbers)),
                                   max_frames)
        txSequenceRewindBuffer <- mkRewindFIFOVariableCommitLevel(clocked_by controllerClk, reset_by controllerRst);

    FIFO#(Int#(32)) frameTimeout <- mkSizedFIFO(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberTX <- mkSizedFIFOF(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackSequenceNumberRX <- mkSizedFIFOF(valueof(max_frames), clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) ackRX <- mkSizedFIFOF(4, clocked_by controllerClk, reset_by controllerRst);
    FIFOF#(Bit#(TLog#(sequence_numbers))) frameInProgress <- mkSizedFIFOF(1, clocked_by controllerClk, reset_by controllerRst); // Must be size 1.
    Reg#(Int#(32)) timer <- mkReg(0, clocked_by controllerClk, reset_by controllerRst);

    // need to make sure that flow control can come through
    PulseWire transmittingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    PulseWire updatingCredits <- mkPulseWire(clocked_by(controllerClk), reset_by(controllerRst));
    MARSHALLER#(Bit#(data_size), Bit#(interface_width)) marshaller <- mkSimpleMarshallerHighToLow(clocked_by(controllerClk),
                                                                                                      reset_by(controllerRst));
    // Incoming BRAM FIFO feeds into a register-based FIFO to relax timing.
    FIFOF#(Tuple2#(Bit#(1), Bit#(width))) serdesInfifo <- mkSizedSlowBRAMFIFOF(valueof(total_credits), clocked_by controllerClk, reset_by controllerRst);

    let timeoutFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);
    let timeoutThreshold = 1000 * (fromInteger(valueof(total_credits)));

    CRCGEN#(ParitySize, Bit#(width)) crcgen <- mkAutoCRCGen();
    // Use a non-zero initial CRC value so that the data value 0 doesn't also
    // hash to a CRC of 0.  For some media this is irrelevant, but it can't hurt.
    let crcInit = 1;

    rule timerCount;
        timer <= timer + 1;
    endrule

    rule sequenceStuffer;
        txSequenceRewindBuffer.enq(sequenceNumberTX);
        sequenceNumberTX <= sequenceNumberTX + 1;
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("TX Sequence number going in rewind buffer");
        end
    endrule

    rule passRewind;
        txDataRewindBuffer.enq(marshaller.first);
        marshaller.deq;
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("TX Marsh: %h", marshaller.first);
        end
    endrule

    // Clock compensation occurs periodically in the phy.  We need to
    // allow it to occur at least once before we attempt to send data.
    rule tickCC(ccCycles > 0 && ugDevice.cc  && unpack(ugDevice.channel_up));
        ccCycles <= ccCycles - 1;
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("Ticking CC  %d", ccCycles);
        end
    endrule


    rule crossDomain;
        marshaller.enq(serdesTxfifo.first);
        serdesTxfifo.deq;
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("TX Link: %h", serdesTxfifo.first);
        end
    endrule


    // ====================================================================
    //
    // Transmit side.
    //
    // We can send three different message classes, which are encoded using
    // the high order bits of the first flit:
    //   0X - normal message
    //   11 - flow control credit
    //   10 - header
    //
    // ====================================================================

    Bit#(parity_size) zeros = 0;

    Wire#(Bit#(width)) hashWire <- mkWire(clocked_by(controllerClk), reset_by(controllerRst));
    RWire#(Bit#(TSub#(width, parity_size))) ctrlPayloadWire <- mkRWire(clocked_by(controllerClk), reset_by(controllerRst));


    rule txHeader (! transmittingCredits &&
                   ! frameInProgress.notEmpty &&
                   ccCycles == 0 &&
                   ugDevice.transmit_rdy);
        Bit#(control_data_size) seqExtend = zeroExtend(txSequenceRewindBuffer.first);
        hashWire <= {zeros, header, seqExtend};

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $write("TX Hashing(header): %h, %h ->", zeros, {header, seqExtend});
        end

        ctrlPayloadWire.wset({header, seqExtend});
        frameInProgress.enq(?);
        // reset fream state
        framePositionTX <= 0;
        txFrames <= txFrames + 1;

        // We start the timeout here so that corrupt partial packets
        // can be retransmitted.
        frameTimeout.enq(timer);
    endrule


    // since there's a timeout on acks we should transmit them quickly.
    rule txFC (ccCycles == 0 && ugDevice.transmit_rdy);
        ackSequenceNumberTX.deq();
        Bit#(control_data_size) ackExtend = zeroExtend(ackSequenceNumberTX.first);

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $write("TX Hashing(ack): %h -> ", {zeros, ack, ackExtend});
        end

        hashWire <= {zeros, ack, ackExtend};
        ctrlPayloadWire.wset({ack, ackExtend});
        transmittingCredits.send;
    endrule

    rule txSend (! transmittingCredits &&
                 frameInProgress.notEmpty &&
                 ugDevice.transmit_rdy);
        txDataRewindBuffer.deq;
        hashWire <= {parityTX, payload, txDataRewindBuffer.first};

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $write("TX Hashing (data[%d]): %h, %h ->", framePositionTX, parityTX, txDataRewindBuffer.first);
        end

        ctrlPayloadWire.wset({payload, txDataRewindBuffer.first});

        if (framePositionTX + 1 == 0) // frame size must be a power of two
        begin
            // next up we should send the sequence number.
            frameInProgress.deq;
            txSequenceRewindBuffer.deq;
            ackSequenceNumberRX.enq(txSequenceRewindBuffer.first);
        end
        else
        begin
            framePositionTX <= framePositionTX + 1;
        end

    endrule

    //
    // Bottom half of three above rules, actually does the transmission.
    //
    (* fire_when_enabled *)
    rule sendData (ctrlPayloadWire.wget matches tagged Valid .topHalf);
        Bit#(parity_size) hashTX = crcgen.nextChunk(crcInit, hashWire);
        if (truncateLSB(topHalf) == payload || truncateLSB(topHalf) == header)
        begin
            parityTX <= hashTX;
        end

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("hash %h", hashTX);
        end

        ugDevice.send({topHalf, hashTX});
    endrule

    //
    // Recover from loss of incoming messages.  Wipe out state and attempt
    // to resume.
    //
    // Timeout is decided in two stages to relax FPGA timing.
    //
    FIFO#(Bool) timeoutQ <- mkFIFO1(clocked_by controllerClk, reset_by controllerRst);

    rule timeoutTest (abs(timer - frameTimeout.first) > timeoutThreshold);
        timeoutQ.enq(?);
    endrule

    rule timeout (True);
        timeoutQ.deq();

        frameTimeout.clear();
        ackSequenceNumberRX.clear();
        frameInProgress.clear();
        txDataRewindBuffer.rewind();
        txSequenceRewindBuffer.rewind();
        timeoutFires.send;
        timeouts <= timeouts + 1;
    endrule


    // ====================================================================
    //
    // Receive side.
    //
    // The receive side consists of a two-stage protocol pipeline. The
    // first stage handles error checking and data aggregation. The
    // second stage handles frame status and acknowledgement.
    //
    // The payloads of the frame (1X) messages will be dropped - only the
    // first flit contains useful information.  Credit updates are decoupled
    // from the main processing pipeline by way of a FIFO.
    //
    //
    // ====================================================================

    DEMARSHALLER#(Bit#(data_size), Bit#(interface_width)) demarshaller <-
        mkSimpleDemarshallerHighToLow(clocked_by(controllerClk),
                                      reset_by(controllerRst));

    // This wire lets us check whether we ever drop data on receive.
    let rxFires <- mkPulseWire(clocked_by controllerClk, reset_by controllerRst);


    // use flit number to distinguish flow control. first flit is header.
    rule rxIntake;  // We always need to receive
        let data <- ugDevice.receive;
        rxFires.send();

        // soft errors mean something bad happened in the encoding/on
        // the channel, so we'll just drop this data.

        serdesInfifo.enq(tuple2(ugDevice.soft_err, data));
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("RX raw: %h", data);
        end
    endrule

    rule fullDeath (!ackRX.notFull || ! serdesInfifo.notFull());
       $display("rxIntake blocks, and we die");
       $finish;
    endrule

    PulseWire dropFires <- mkPulseWire(clocked_by(controllerClk),
                                       reset_by(controllerRst));

    rule drop (! rxFires && ugDevice.receive_rdy());
        dataDrops <= dataDrops + 1;
        dropFires.send;
    endrule

    rule handleAck (ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        // If this was an expected ack, take action
        if ((ackSequenceNumberRX.first == ackRX.first))
        begin
            frameTimeout.deq;
            ackSequenceNumberRX.deq;
            txDataRewindBuffer.commit(tagged Valid fromInteger(valueof(frame_size)));
            txSequenceRewindBuffer.commit(tagged Valid 1);
            txFramesCorrect <= txFramesCorrect + 1;
            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("RX ACK: %d", ackRX.first);
            end

        end
        else
        begin
            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("RX ACK: (dropped) expected: %d got: %d", ackSequenceNumberRX.first(), ackRX.first);
            end
        end
    endrule

    // drop ack (we got a duplicate ack/some unexpected state)
    rule dropAck (! ackSequenceNumberRX.notEmpty);
        ackRX.deq;
        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("RX ACK: (dropped) unexpected, got: %d", ackRX.first);
        end
    endrule

    // If we put data into the demarshaller it must be known, correct, data.
    rule rxDemarsh;
        serdesInfifo.deq();
        match {.softErr, .rawFragment} = serdesInfifo.first;

        Tuple3#(Bit#(1), Bit#(data_size), Bit#(parity_size)) fragment = unpack(rawFragment);

        match {.ctrl, .data, .hashExpected} = fragment;

        Bool isPayload = ctrl == payload;
        Bool isAck = truncateLSB(rawFragment) == ack;
        Bool isHeader = truncateLSB(rawFragment) == header;

        // Since we have cleverly aligned the packets, all hash computations
        // are the same.
        Bit#(parity_size) hashSalt = (isPayload) ? parityRX : 0;
        Bit#(parity_size) hashRX = crcgen.nextChunk(crcInit,
                                                    zeroExtend({hashSalt, ctrl, data}));
        Bool notCorrupt = ((hashRX == hashExpected) && (softErr == 0));

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("**************");
            $display("RX Hashes(parityRX %h): %h, %h = %h/%h", parityRX, hashSalt, data, hashRX, hashExpected);

            $display("Fragment isPayload: %h isAck: %h, isHeader:%h", isPayload, isAck, isHeader);
        end

        if (isPayload)
        begin
            parityRX <= hashRX;

            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("Handle payload");
            end

            //
            // Acks may get dropped.  We need to ack every correct packet.
            // However, we can't spuriously ack future packets.  To handle
            // this, we need to have a few forbidden packets.
            //

            provisionalFramePositionRX <= provisionalFramePositionRX + 1;

            //
            // Only enq if
            //   1) hash matches
            //   2) no previous errors in the frame
            //   3) we haven't enqueued this data already (i.e.) as part
            //      of a correct partial frame.
            //

            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("RX Data: pos: %d hashExpected: %h hashRX: %h, data: %h", provisionalFramePositionRX, hashExpected, hashRX, serdesInfifo.first);
                $display("RX Status: pPos %d pSeq %d pos %d seq %d frameErrorRX %d", provisionalFramePositionRX, provisionalSequenceNumberRX, framePositionRX, sequenceNumberRX, frameErrorRX);

            end

            if (notCorrupt && ! frameErrorRX)
            begin
                // If we haven't seen this data before and we don't have an error,
                // send it to the upper level.
                if ((provisionalFramePositionRX == framePositionRX) &&
                    (provisionalSequenceNumberRX == sequenceNumberRX))
                begin
                    demarshaller.enq(data);

                    // frame_size must be a power of two
                    if (framePositionRX + 1 == 0)
                    begin
                        // next up we should send the sequence number.
                        // We need to see a header before commencing data.
                        frameErrorRX <= True;
                        // We completed a packet.
                        sequenceNumberRX <= sequenceNumberRX + 1;
                        rxFramesCorrect <= rxFramesCorrect + 1;
                    end

                    framePositionRX <= framePositionRX + 1;

                    if (`AURORA_RELIABLE_DEBUG > 0)
                    begin
                        $display("RX Marsh: %h", data);
                    end

                end
                else
                begin
                    if (`AURORA_RELIABLE_DEBUG > 0)
                    begin
                        $display("RX Marsh: (repeat) %h", data);
                    end
                end
                // If we got a frame without error, then we should send an ack.
                // frame_size must be a power of two.
                if (provisionalFramePositionRX + 1 == 0)
                begin
                    if (`AURORA_RELIABLE_DEBUG > 0)
                    begin
                        $display("RX Sending ACK");
                    end

                    // If we got the last data correctly send an ack.
                    rxFramesAcked <= rxFramesAcked + 1;
                    ackSequenceNumberTX.enq(provisionalSequenceNumberRX);
                end
            end
            else
            begin
                // Need to shoot down whatever is in the marshaller
                if (`AURORA_RELIABLE_DEBUG > 0)
                begin
                    $display("RX Marsh: (drop) %h", data);
                end

                frameErrorRX <= True;
            end
        end
        else if (isHeader)
        begin
            Bit#(TLog#(sequence_numbers)) headerSequence = truncate(data);
            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("Handle header");
            end
            rxFrames <= rxFrames + 1;

            // Getting a header should cause us to reset our counters.
            // (We should do this at the higher level.)
            provisionalFramePositionRX <= 0;

            // Did we get the right sequence number?  Since acks may be
            // dropped at the transmitter, we have a set of frames that we
            // will acknowledge.  Future frames will not be acknowledged.
            // To deal with wrap around, we use an enlarged frame space.
            // The second or clause handles the wrap case.

            Bit#(1) headerTop = truncateLSB(headerSequence);
            Bit#(1) seqTop = truncateLSB(sequenceNumberRX);

            // Second clause handles the wrap-around case, where the leading
            // 0 packets are younger than the leading 1 packets.
            Bool frameErrorNext = (sequenceNumberRX < truncate(headerSequence) &&
                                   !  (headerTop == 1 &&
                                      (sequenceNumberRX < fromInteger(valueof(max_frames))))) ||
                                  (seqTop == 1 && (headerSequence < fromInteger(valueof(max_frames)))) ||
                                   ! notCorrupt;

            frameErrorRX <= frameErrorNext;
            provisionalSequenceNumberRX <= headerSequence;

            parityRX <= hashRX;

            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("RX Header: seq_no: %d", data);
                $display("frame error %d, seq clause %d, wrap clause %d", frameErrorNext, (sequenceNumberRX < truncate(headerSequence)), (seqTop == 1 && ((headerSequence < fromInteger(valueof(max_frames))))));
            end
        end
        else if (isAck)
        begin
            if (`AURORA_RELIABLE_DEBUG > 0)
            begin
                $display("Handle Ack");
            end

            if (notCorrupt)
            begin
                ackRX.enq(truncate(data));
            end
        end

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("**************");
        end
    endrule


    rule rxDone;
        demarshaller.deq;
        serdesRxfifo.enq(truncate(demarshaller.first()));

        if (`AURORA_RELIABLE_DEBUG > 0)
        begin
            $display("RX Link: %h", demarshaller.first);
        end
    endrule


    rule sendUnderflow;
        ugDevice.underflow(frameErrorRX, zeroExtend({pack(dropFires), pack(timeoutFires)}), zeroExtend(txSequenceRewindBuffer.first), zeroExtend(sequenceNumberRX));
    endrule

    interface AURORA_WIRES wires;
        method rxp_in = ugDevice.rxp_in;
        method rxn_in = ugDevice.rxn_in;
        method txp_out = ugDevice.txp_out;
        method txn_out = ugDevice.txn_out;
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
