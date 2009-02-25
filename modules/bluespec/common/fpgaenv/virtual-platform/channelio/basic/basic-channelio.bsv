import FIFOF::*;
import Vector::*;

`include "physical_platform.bsh"
`include "physical_channel.bsh"
`include "umf.bsh"

// read/write port interfaces
interface CIOReadPort;
    method ActionValue#(UMF_PACKET) read();
endinterface

interface CIOWritePort;
    method Action write(UMF_PACKET data);
endinterface

// channelio interface
interface CHANNEL_IO;
    interface Vector#(`CIO_NUM_CHANNELS, CIOReadPort)  readPorts;
    interface Vector#(`CIO_NUM_CHANNELS, CIOWritePort) writePorts;
endinterface

// channelio module
module mkChannelIO#(PHYSICAL_DRIVERS drivers) (CHANNEL_IO);

    Reg#(UMF_MSG_LENGTH) readChunksRemaining  <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) writeChunksRemaining <- mkReg(0);

    Reg#(Bit#(8)) currentReadChannel  <- mkReg(0);
    Reg#(Bit#(8)) currentWriteChannel <- mkReg(0);

    // physical channel
    PHYSICAL_CHANNEL physicalChannel <- mkPhysicalChannel(drivers);

    // ==============================================================
    //                        Ports and Buffers
    // ==============================================================

    // create read/write buffers and link them to ports
    FIFOF#(UMF_PACKET)                       readBuffers[`CIO_NUM_CHANNELS];
    Vector#(`CIO_NUM_CHANNELS, CIOReadPort)  rports = newVector();

    FIFOF#(UMF_PACKET)                       writeBuffers[`CIO_NUM_CHANNELS];
    Vector#(`CIO_NUM_CHANNELS, CIOWritePort) wports = newVector();

    for (Integer i = 0; i < `CIO_NUM_CHANNELS; i = i+1)
    begin
        readBuffers[i] <- mkSizedFIFOF(4);
        writeBuffers[i] <- mkSizedFIFOF(4);

        // create a new read port and link it to the FIFO
        rports[i] = interface CIOReadPort
                        method ActionValue#(UMF_PACKET) read();

                            UMF_PACKET val = readBuffers[i].first();
                            readBuffers[i].deq();
                            return val;

                        endmethod
                    endinterface;

        // create a new write port and link it to the FIFO
        wports[i] = interface CIOWritePort
                        method Action write(UMF_PACKET data);

                            writeBuffers[i].enq(data);

                        endmethod
                    endinterface;
    end

    // ==============================================================
    //                          Read rules
    // ==============================================================

    // probe physical channel for incoming new message header
    rule read_physical_channel_newmsg (readChunksRemaining == 0);

        UMF_CHUNK chunk <- physicalChannel.read();

        // create new header packet
        UMF_PACKET packet = tagged UMF_PACKET_header unpack(chunk);

        // enqueue the new header into the channel's FIFO
        readBuffers[packet.UMF_PACKET_header.channelID].enq(packet);

        // setup channel for remaining chunks
        readChunksRemaining <= packet.UMF_PACKET_header.numChunks;
        currentReadChannel  <= zeroExtend(packet.UMF_PACKET_header.channelID);

    endrule

    // probe physical channel for incoming read data (continuing old message)
    rule read_physical_channel_contmsg (readChunksRemaining != 0);

        UMF_CHUNK chunk <- physicalChannel.read();
        UMF_PACKET packet = tagged UMF_PACKET_dataChunk chunk;

        readBuffers[currentReadChannel].enq(packet);

        // increment chunks read
        readChunksRemaining <= readChunksRemaining - 1;

    endrule

    // ==============================================================
    //                          Write rules
    // ==============================================================

    Bool request[`CIO_NUM_CHANNELS];
    Bool higher_priority_request[`CIO_NUM_CHANNELS];
    Bool grant[`CIO_NUM_CHANNELS];

    // static loop for all write channels
    for (Integer i = 0; i < `CIO_NUM_CHANNELS; i = i + 1)
    begin

        // compute priority for this channel (static request/grant)
        // current algorithm involves a chain OR, which is fine for
        // a small number of channels

        request[i] = (writeChunksRemaining == 0) && (writeBuffers[i].notEmpty());

        if (i == 0)
        begin
            grant[i] = request[i];
            higher_priority_request[i] = request[i];
        end
        else
        begin
            grant[i] = (!higher_priority_request[i-1]) && request[i];
            higher_priority_request[i] = higher_priority_request[i-1] || request[i];
        end

        // start writing new message
        rule write_physical_channel_newmsg (grant[i]);

            // get header packet
            UMF_PACKET packet = writeBuffers[i].first();
            writeBuffers[i].deq();

            // create and encode header chunk
            //   TODO: ideally, we should explicitly set channelID here. For
            //   now, assume upper layer is setting it correctly (upper layer
            //   has to know its virtual channelID anyway
            UMF_CHUNK headerChunk = pack(packet.UMF_PACKET_header);

            // send the header chunk to the physical channel
            physicalChannel.write(headerChunk);

            // setup remaining chunks
            writeChunksRemaining <= packet.UMF_PACKET_header.numChunks;
            currentWriteChannel <= fromInteger(i);

        endrule

    end // for

    // continue writing message
    rule write_physical_channel_continue (writeChunksRemaining != 0);

        // get the next packet from the active write channel
        UMF_PACKET packet = writeBuffers[currentWriteChannel].first();
        writeBuffers[currentWriteChannel].deq();

        // send the data chunk to the physical channel
        physicalChannel.write(packet.UMF_PACKET_dataChunk);

        // one more chunk processed
        writeChunksRemaining <= writeChunksRemaining - 1;

    endrule

    // ==============================================================
    //                        Set Interfaces
    // ==============================================================

    interface readPorts = rports;
    interface writePorts = wports;

endmodule
