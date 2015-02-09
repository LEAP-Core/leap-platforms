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

import Vector::*;
import GetPut::*;
import Connectable::*;
import FIFO::*;
import FIFOLevel::*;
import Clocks::*;
import MsgFormat::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/pcie_device.bsh"
`include "awb/provides/umf.bsh"
`include "awb/provides/fpga_components.bsh"



//
// Internal state shared between canStartPacketToHost and the rule that
// emits packet headers.
//
typedef struct
{
    // True if this BlueNoC packet is also the start of a UMF packet
    Bool isUMFStart;

    // Chunks in the current BlueNoC packet
    UInt#(8) bnChunks;

    // Remaining chunks in the UMF packet
    UMF_MSG_LENGTH umfChunks;
}
PHYSICAL_CHANNEL_TO_HOST_STATE
    deriving (Eq, Bits);


//
// Used only for debugging, log packet history so it can be dumped and compared
// to expected values.
//
typedef Bit#(`BLUENOC_HISTORY_INDEX_BITS) PHYSICAL_CHANNEL_HISTORY_IDX;


// PCIE_DEVICE_IFC--
//
//   By convention a Device is a driver and a wires.
//
interface PCIE_DEVICE;
    interface PCIE_DRIVER driver;
    interface PCIE_WIRES  wires;
endinterface

// module
module mkPCIEDevice#(Clock rawClock, Reset rawReset)
    // Interface
    (PCIE_DEVICE);
   
    PCIE_LOW_LEVEL_DEVICE pcieLLDev <- mkPCIELowLevelDevice(rawClock,
                                                            rawReset);

    //
    // The channel is written with the following assumptions:
    //
    if (valueOf(SizeOf#(UMF_PACKET_HEADER)) - valueOf(UMF_PACKET_HEADER_FILLER_BITS) > 32)
        errorM("UMF packet header must fit in 32 bits");
    if (valueOf(PCIE_BYTES_PER_BEAT) < 8)
        errorM("PCIE_BYTES_PER_BEAT must be at least 8");
    if (valueOf(PCIE_BYTES_PER_BEAT) * 8 != valueOf(UMF_CHUNK_BITS))
        errorM("PCIE_BYTES_PER_BEAT must be equal to the size of UMF chunks");

    let modelClk <- exposeCurrentClock();
    let modelRst <- exposeCurrentReset();

    // Maximum UMF payload chunks that fit in a BlueNoC packet
    Integer maxChunksPerPacket = (256 / valueOf(PCIE_BYTES_PER_BEAT)) - 1;

    let pcieDriver = pcieLLDev.driver;
    let pcieClk = pcieDriver.clock;
    let pcieRst = pcieDriver.reset;
    let pcieNOC = pcieDriver.noc;

    FifoMsgSink#(PCIE_BYTES_PER_BEAT)   beatsIn  <- mkFifoMsgSink(clocked_by pcieClk, reset_by pcieRst);
    FifoMsgSource#(PCIE_BYTES_PER_BEAT) beatsOut <- mkFifoMsgSource(clocked_by pcieClk, reset_by pcieRst);
    mkConnection(pcieNOC, as_port(beatsOut.source, beatsIn.sink));

    // Transfer from PCIe clock to model clock
    SyncFIFOIfc#(UMF_CHUNK) fromHostSyncQ <- mkSyncFIFO(8, pcieClk, pcieRst, modelClk);

    // FPGA to host provides enough buffering for two full BlueNoC packets
    // in order to support guaranteeing that BlueNoC packets will not be
    // started until it is certain the whole packet is available.
    // *** While a mkSyncFIFOCount would seem appropriate, the fact that the
    // *** dCount is conservative sometimes prevents packet processing.
    // *** Instead, we use an extra buffer with an accurate counting FIFO in
    // *** the PCIe clock domain.
    SyncFIFOIfc#(UMF_CHUNK) toHostSyncQ <- mkSyncFIFO(8, modelClk, modelRst, pcieClk);
    FIFOCountIfc#(UMF_CHUNK, TDiv#(512, PCIE_BYTES_PER_BEAT)) toHostCountedQ <-
        mkFIFOCount(clocked_by pcieClk, reset_by pcieRst);
    mkConnection(toGet(toHostSyncQ), toPut(toHostCountedQ));

    //
    // Count cycles of inactivity before forcing a flush of the FPGA to host
    // output buffer.
    //
    Reg#(Bit#(11)) inactiveOutCnt <- mkReg(0, clocked_by pcieClk, reset_by pcieRst);
    Reg#(Bit#(11)) maxTimeout <- mkReg(0, clocked_by pcieClk, reset_by pcieRst);

    // FPGA -> host policy.  When true, a BlueNoC packet is not allowed to
    // start until the full packet is buffered.  This may avoid deadlock
    // in the PCIe channel.
    Reg#(Bool) waitForFullPacket <- mkReg(False, clocked_by pcieClk, reset_by pcieRst);

    //
    // Wait for a single beat message from the host to know that the channel
    // is up.  No response is expected.
    //
    CrossingReg#(Bool) initDone <-
        mkNullCrossingReg(modelClk, False, clocked_by pcieClk, reset_by pcieRst);
    Reg#(Bool) initDone_Model  <- mkReg(False);


    //
    // Debugging and history buffer state management
    //

    let debugPort = 'hff;
    Reg#(Bool) inDebugPacket <- mkReg(False, clocked_by pcieClk, reset_by pcieRst);

    MEMORY_IFC#(PHYSICAL_CHANNEL_HISTORY_IDX, UMF_CHUNK) historyFromHost <-
        (`BLUENOC_HISTORY_INDEX_BITS != 0) ?
            mkBRAMInitialized(~0, clocked_by pcieClk, reset_by pcieRst) :
            mkNullMemory(clocked_by pcieClk, reset_by pcieRst);

    Reg#(PHYSICAL_CHANNEL_HISTORY_IDX) historyFromHostNext <-
        mkReg(0, clocked_by pcieClk, reset_by pcieRst);
    Reg#(PHYSICAL_CHANNEL_HISTORY_IDX) historyDumpIdx <-
        mkReg(0, clocked_by pcieClk, reset_by pcieRst);

    function Action logHistoryFromHost(UMF_CHUNK chunk);
    action
        historyFromHost.write(historyFromHostNext, chunk);
        historyFromHostNext <= historyFromHostNext + 1;
    endaction
    endfunction


    //
    // Initialization
    //

    (* fire_when_enabled, no_implicit_conditions *)
    rule initModel (True);
        initDone_Model <= initDone.crossed();
    endrule

    rule initFromHost (! beatsIn.empty && ! initDone);
        let beat = beatsIn.first();
        beatsIn.deq();

        initDone <= True;

        // We can't use a dynamic parameter to set configuration
        // because the channel needs to be up to set a parameter.
        // Instead, the values are passed in the initialization
        // payload.
        waitForFullPacket <= unpack(beat[32]);
        maxTimeout <= beat[43:33];
    endrule


    // Remaining bytes in an incoming BlueNoC packet
    Reg#(UInt#(8)) remBytesIn <- mkReg(0, clocked_by pcieClk, reset_by pcieRst);

    //
    // processHeaderFromHost --
    //   Process a BlueNoC packet header arriving from the host.
    //
    rule processHeaderFromHost (! beatsIn.empty &&
                                initDone &&
                                (remBytesIn == 0) &&
                                (beatsIn.first()[7:0] != debugPort));
        let beat = beatsIn.first();
        beatsIn.deq();
        
        // Number of payload bytes.  Some bytes of the payload are in the
        // remainder of this beat, so subtract them from the count.
        UInt#(8) rem_bytes_in = unpack(beat[23:16]);
        UInt#(8) header_data_bytes = fromInteger(valueOf(TSub#(PCIE_BYTES_PER_BEAT, 4)));
        if (rem_bytes_in > header_data_bytes)
        begin
            remBytesIn <= rem_bytes_in - header_data_bytes;
        end

        // The longest BlueNoC packets are shorter than the longest UMF
        // packet allowed.  For long UMF packets a BlueNoC header may arrive
        // with no corresponding UMF header.  This is signalled by setting
        // bit 31 in the BlueNoC header (OP bit 6) for continuation packets.
        Bool contains_umf_header = (beat[31] == 0);

        if (contains_umf_header)
        begin
            // Extract the UMF header from the remainder of the beat
            let umf_header = beat[63:32];
            fromHostSyncQ.enq(unpack(zeroExtend(umf_header)));
        end

        // Log the incoming beat (for debugging).  When BlueNoC beats are larger
        // than 8 bytes there is extra, unused, space in the beat.  Write a
        // value there indicating the packet was detected as a header.
        Bit#(32) hist_tag = (contains_umf_header ? 'hcafef00d : 'hdeadbeef);
        UMF_CHUNK hist_log_beat = resize({ hist_tag, beat[63:0] });
        logHistoryFromHost(hist_log_beat);
    endrule

    //
    // fwdChunkFromHost --
    //   Forward one UMF chunk from the host to the FPGA.
    //
    rule fwdChunkFromHost (! beatsIn.empty && initDone && (remBytesIn != 0));
        let beat = beatsIn.first();
        beatsIn.deq();

        // Debugging log
        logHistoryFromHost(beat);

        // The chunk fills the beat
        fromHostSyncQ.enq(unpack(beat));

        // Done with BlueNoC packet?
        if (remBytesIn > fromInteger(valueOf(PCIE_BYTES_PER_BEAT)))
        begin
            // No.  Continue streaming.
            remBytesIn <= remBytesIn - fromInteger(valueOf(PCIE_BYTES_PER_BEAT));
        end
        else
        begin
            // Yes.  Wait for a header.
            remBytesIn <= 0;
        end
    endrule


    // Number of bytes remaining in current BlueNoC packet
    Reg#(UInt#(8)) remBytesOut <- mkReg(0, clocked_by pcieClk, reset_by pcieRst);
    // Number of chunks remaining in current UMF packet
    Reg#(UMF_MSG_LENGTH) remChunksOut <- mkReg(0, clocked_by pcieClk, reset_by pcieRst);

    //
    // canStartPacketToHost --
    //   Function to compute whether the next packet from FPGA to host may
    //   begin.
    //
    function Maybe#(PHYSICAL_CHANNEL_TO_HOST_STATE) canStartPacketToHost();
        if (! toHostCountedQ.notEmpty)
        begin
            // Nothing to send
            return tagged Invalid;
        end
        else
        begin
            // Compute the length of the next BlueNoC packet.  It will be
            // the smaller of the maximum length and the length of the
            // UMF packet.
            UMF_MSG_LENGTH bn_payload_chunks;
            PHYSICAL_CHANNEL_TO_HOST_STATE state;
            Bool data_ready;

            state.isUMFStart = (remChunksOut == 0);

            if (state.isUMFStart)
            begin
                UMF_PACKET_HEADER umf_header = unpack(toHostCountedQ.first());

                state.umfChunks = umf_header.numChunks;
                bn_payload_chunks = min(umf_header.numChunks,
                                        fromInteger(maxChunksPerPacket));

                // GT because must also have a packet header
                data_ready = (toHostCountedQ.count > resize(bn_payload_chunks));
            end
            else
            begin
                // Continuation of existing UMF packet
                state.umfChunks = remChunksOut;
                bn_payload_chunks = min(remChunksOut,
                                        fromInteger(maxChunksPerPacket));

                data_ready = (toHostCountedQ.count >= resize(bn_payload_chunks));
            end

            state.bnChunks = unpack(resize(bn_payload_chunks));

            // May begin sending if the waitForFullPacket policy is not set
            // or if a full packet is buffered.
            return (data_ready || ! waitForFullPacket) ?
                     tagged Valid state :
                     tagged Invalid;
        end
    endfunction


    //
    // startBlueNoCPacketToHost --
    //   Begin a new BlueNoC packet.  This may be the continuation of a
    //   UMF packet or the start of a new UMF packet.
    //
    rule startBlueNoCPacketToHost (initDone &&&
                                   (remBytesOut == 0) &&&
                                   ! inDebugPacket &&&
                                   canStartPacketToHost() matches tagged Valid .state);
        let chunk = toHostCountedQ.first();

        if (state.isUMFStart)
        begin
            toHostCountedQ.deq();
        end

        Bit#(8) flags = 0;
        // Continuation of UMF chunk?
        flags[7] = pack(! state.isUMFStart);

        // Generate the UMF header value unconditionally to simplify hardware.
        // The receiver will look at flag bit 7 to know whether a header
        // exists.  When no header is needed the remainder of the beat
        // will be ignored, allowing the stream of chunks to be chunk-aligned.
        UMF_PACKET_HEADER umf_header = unpack(pack(chunk));

        //
        // Compute the length of the BlueNoC packet.  If the UMF packet
        // fits in a BlueNoC packet then set the BlueNoC packet length
        // to end when the UMF packet ends.  Otherwise, send a full
        // BlueNoC packet.
        //
        UInt#(8) rem_bytes_out = state.bnChunks *
                                 fromInteger(valueOf(PCIE_BYTES_PER_BEAT));

        remBytesOut <= rem_bytes_out;
        remChunksOut <= state.umfChunks;

        // Set don't wait (send immediately) flag if this is the last
        // BlueNoC packet for the UMF packet and maxTimeout is 0.
        inactiveOutCnt <= maxTimeout;
        if (maxTimeout == 0)
        begin
            // One BlueNoC packet or multiple packets?
            Bool last_bn_packet = (state.umfChunks <=
                                   fromInteger(maxChunksPerPacket));
            flags[0] = pack(last_bn_packet);
        end

        let len = rem_bytes_out +
                  fromInteger(valueOf(TSub#(PCIE_BYTES_PER_BEAT, 4)));

        // The UMF header must fit in 32 bits!
        Bit#(64) beat = { pack(umf_header)[31:0],
                          flags,
                          pack(len),                 // Length
                          8'd4,                      // Source
                          8'd0 };                    // Destination

        beatsOut.enq(zeroExtend(beat));
    endrule

    //
    // fwdChunkToHost --
    //   The continuation of both BlueNoC and UMF packets.
    //
    rule fwdChunkToHost (remBytesOut != 0);
        let chunk = toHostCountedQ.first();
        toHostCountedQ.deq();

        beatsOut.enq(pack(chunk));

        remChunksOut <= remChunksOut - 1;
        inactiveOutCnt <= maxTimeout;

        // Done with BlueNoC packet?
        if (remBytesOut > fromInteger(valueOf(PCIE_BYTES_PER_BEAT)))
        begin
            // No.  Continue streaming.
            remBytesOut <= remBytesOut - fromInteger(valueOf(PCIE_BYTES_PER_BEAT));
        end
        else
        begin
            // Yes.  Start a new BlueNoC packet.
            remBytesOut <= 0;
        end
    endrule

    //
    // triggerTimeout --
    //   Flush the FPGA->host data if it appears no more packets are coming.
    //   This rule never fires in the middle of a packet.
    //
    rule triggerTimeout ((inactiveOutCnt != 0) &&
                         (remBytesOut == 0) &&
                         ! inDebugPacket &&
                         ! isValid(canStartPacketToHost()));
        if (inactiveOutCnt == 1)
        begin
            Bit#(32) beat = { 8'd1,       // Don't wait
                              8'd0,       // Length
                              8'd4,       // Source
                              8'd0 };     // Destination
            beatsOut.enq(zeroExtend(beat));
        end

        inactiveOutCnt <= inactiveOutCnt - 1;
    endrule


    //
    // debug --
    //   Status request initiated by software.  Both the incoming and outgoing
    //   packets are single beats.  This would work better as PCIe CSRs.
    //
    rule debug (! beatsIn.empty &&
                initDone &&
                (remBytesOut == 0) &&
                (remBytesIn == 0) &&
                ! inDebugPacket &&
                (beatsIn.first()[7:0] == debugPort));
        let beat = beatsIn.first();

        let out_beat = beat;
        out_beat[7:0] = beat[15:8];        // Swap source and destination
        out_beat[15:8] = beat[7:0];
        out_beat[23:16] = 4;               // Length
        out_beat[31:24] = 1;               // Don't wait

        if (beat[31] == 0)
        begin
            beatsIn.deq();

            // High flag bit clear -- normal debug state
            out_beat[32] = pack(fromHostSyncQ.notFull);
            out_beat[39:33] = 0;

            out_beat[47:40] = zeroExtend(pack(toHostCountedQ.count));
            out_beat[63:48] = zeroExtend(remChunksOut);
        end
        else if (`BLUENOC_HISTORY_INDEX_BITS != 0)
        begin
            //
            // Debug packet is a history log request.  The incoming request
            // beat will be held in beatsIn while the code here cycles
            // through all values of historyDumpIdx.
            //
            let idx = historyDumpIdx;
            out_beat[63:32] = zeroExtend(idx);
            historyFromHost.readReq(historyFromHostNext + truncate(idx));

            // The history takes an entire beat.  Lock the channel by setting
            // inDebugPacket and send the header beat.  The history log
            // read response will trigger the payload beat.
            inDebugPacket <= True;
            // Adjust length
            out_beat[23:16] = fromInteger(valueOf(TSub#(TMul#(2, PCIE_BYTES_PER_BEAT), 4)));

            // Done with dump?
            if (idx == maxBound)
            begin
                // Indicate last packet
                out_beat[31] = 1;
                beatsIn.deq();
            end
                
            historyDumpIdx <= idx + 1;
        end
        else
        begin
            beatsIn.deq();
        end

        beatsOut.enq(out_beat);
    endrule

    //
    // fwdHistoryFromHost --
    //   Complete the debug packet response by sending a from-host history
    //   log entry.
    //
    (* descending_urgency = "fwdHistoryFromHost, debug, startBlueNoCPacketToHost" *)
    (* descending_urgency = "fwdHistoryFromHost, debug, triggerTimeout" *)
    rule fwdHistoryFromHost (remBytesOut == 0);
        let hist <- historyFromHost.readRsp();
        beatsOut.enq(hist);

        inDebugPacket <= False;
    endrule
   
    Wire#(Maybe#(UMF_CHUNK)) writeData <- mkDWire(tagged Invalid);

    // Some debugging logic
    if(`BLUENOC_CHIPSCOPE_DEBUG != 0)
    begin
        let ila <- mkILA;
        let icon <- mkICON;
        Reg#(Bit#(2)) switch <- mkReg(0);

        rule incrReg;
            switch <= switch + 1;
        endrule 

        mkConnection(ila.control, icon.control);

        rule driveILA;
            ila.trig0(zeroExtend({switch,
                                  pack(isValid(writeData)),
                                  pack(initDone_Model), 
                                  pack(toHostSyncQ.notFull()), 
                                  pack(fromHostSyncQ.notEmpty())}));
        endrule

        rule driveILA2;
            ila.trig3(truncateLSB(fromHostSyncQ.first));
            ila.trig4(truncate(fromHostSyncQ.first));
        endrule

        rule driverILA3(writeData matches tagged Valid .data);
            ila.trig1(truncateLSB(data));
            ila.trig2(truncate(data));
        endrule

    end


    interface PCIE_DRIVER driver;
        method Action write(UMF_CHUNK data) if (initDone_Model);
            toHostSyncQ.enq(data);
            writeData <= tagged Valid data;
        endmethod
       
        method ActionValue#(UMF_CHUNK) read();
            let c = fromHostSyncQ.first();
            fromHostSyncQ.deq();

            return c;
        endmethod

        method first = fromHostSyncQ.first;
        
        method deq = fromHostSyncQ.deq;

        method write_ready = initDone_Model && toHostSyncQ.notFull();

        interface clock = pcieDriver.clock;
        interface reset = pcieDriver.reset;
        
    endinterface
        
    interface wires = pcieLLDev.wires;

endmodule
