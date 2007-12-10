import FIFOF::*;
import Vector::*;

`include "toplevel_wires.bsh"

`define CIO_NULL        'hFFFFFFFF00000000
`define POLL_INTERVAL   32

`define UMF_CHUNK_BITS      32
`define UMF_CHUNK_BYTES     4
`define UMF_CHUNK_LOG_BYTES 2

`define UMF_CHANNEL_ID_BITS 4
`define UMF_SERVICE_ID_BITS 8
`define UMF_METHOD_ID_BITS  4
`define UMF_MSG_LENGTH_BITS 16

typedef Bit#(`UMF_CHUNK_BITS)       UMF_CHUNK;

typedef Bit#(`UMF_CHANNEL_ID_BITS)  UMF_CHANNEL_ID;
typedef Bit#(`UMF_SERVICE_ID_BITS)  UMF_SERVICE_ID;
typedef Bit#(`UMF_METHOD_ID_BITS)   UMF_METHOD_ID;
typedef Bit#(`UMF_MSG_LENGTH_BITS)  UMF_MSG_LENGTH;

typedef union tagged
{
    struct
    {
        UMF_CHANNEL_ID  channelID;
        UMF_SERVICE_ID  serviceID;
        UMF_METHOD_ID   methodID;
        UMF_MSG_LENGTH  length;
    }
    UMF_PACKET_header;

    UMF_CHUNK   UMF_PACKET_dataChunk;

} UMF_PACKET
    deriving (Bits);

// BDPI imports
import "BDPI" function Action                 cio_init();
import "BDPI" function ActionValue#(Bit#(8))  cio_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(64)) cio_read(Bit#(8) handle);
import "BDPI" function Action   cio_write(Bit#(8) handle, Bit#(32) data);

// read/write port interfaces
interface CIOReadPort;
    method ActionValue#(UMF_PACKET) read();
endinterface

interface CIOWritePort;
    method Action write(UMF_PACKET data);
endinterface

// channelio interface
interface ChannelIO;
    interface Vector#(`CIO_NUM_CHANNELS, CIOReadPort)   readPorts;
    interface Vector#(`CIO_NUM_CHANNELS, CIOWritePort) writePorts;
endinterface

// channelio module
module mkChannelIO#(TopLevelWiresDriver wires) (ChannelIO);

    Reg#(Bit#(8))   handle              <- mkReg(0);
    Reg#(Bit#(2))   ready               <- mkReg(0);
    Reg#(Bit#(32))  pollCounter         <- mkReg(0);

    Reg#(UMF_MSG_LENGTH) readChunksRemaining  <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) writeChunksRemaining <- mkReg(0);

    Reg#(Bit#(8)) currentReadChannel  <- mkReg(0);
    Reg#(Bit#(8)) currentWriteChannel <- mkReg(0);

    // create read/write buffers and link them to ports
    FIFOF#(UMF_PACKET)                       readBuffers[`CIO_NUM_CHANNELS];
    Vector#(`CIO_NUM_CHANNELS, CIOReadPort)  rports = newVector();
    FIFOF#(UMF_PACKET)                       writeBuffers[`CIO_NUM_CHANNELS];
    Vector#(`CIO_NUM_CHANNELS, CIOWritePort) wports = newVector();

    for (Integer i = 0; i < `CIO_NUM_CHANNELS; i = i+1)
    begin
        readBuffers[i] <- mkFIFOF();
        writeBuffers[i] <- mkFIFOF();

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
    //                 C code initialization rules
    // ==============================================================

    // poll cycle
    rule cycle_poll_counter(ready == 1);
        if (pollCounter == `POLL_INTERVAL)
            pollCounter <= 0;
        else
            pollCounter <= pollCounter + 1;
    endrule

    // initialize C code
    rule initialize(ready == 0);
        cio_init();
        ready <= 2;
    endrule

    // another rule needed to initialize C code
    rule open_C_channel(ready == 2);
        Bit#(8) wire_out <- cio_open(0);
        handle <= wire_out;
        ready  <= 1;
    endrule

    // ==============================================================
    //                          Read rules
    // ==============================================================

    // probe C code for incoming new message header
    rule read_physical_channel_newmsg (ready == 1       &&
                                       pollCounter == 0 &&
                                       readChunksRemaining == 0);

        Bit#(64) data <- cio_read(handle);

        // CIO_NULL implies "no data"
        if (data != `CIO_NULL)
        begin

            // header format is hardcoded, TODO: generalize
            UMF_CHANNEL_ID  cid = data[31:28];
            UMF_SERVICE_ID  sid = data[27:20];
            UMF_METHOD_ID   mid = data[19:16];
            UMF_MSG_LENGTH  len = data[15:0];

            // create new header packet
            UMF_PACKET packet = tagged UMF_PACKET_header
                                {
                                    channelID: cid,
                                    serviceID: sid,
                                    methodID : mid,
                                    length   : len
                                };

            // enqueue the new header into the channel's FIFO
            readBuffers[cid].enq(packet);

            // setup channel for remaining chunks
            UMF_MSG_LENGTH totalchunks = len >> `UMF_CHUNK_LOG_BYTES;

            if ((totalchunks & (`UMF_CHUNK_BITS - 1)) != 0)
                readChunksRemaining <= totalchunks;
            else
                readChunksRemaining <= totalchunks - 1;

            currentReadChannel <= zeroExtend(cid);

        end

    endrule

    // probe C code for incoming read data (continuing old message)
    rule read_physical_channel_contmsg (ready == 1           &&
                                        pollCounter == 0     &&
                                        readChunksRemaining != 0);

        Bit#(64) data <- cio_read(handle);

        // CIO_NULL implies "no data"
        if (data != `CIO_NULL)
        begin

            UMF_CHUNK  chunk  = data[`UMF_CHUNK_BITS - 1 : 0];
            UMF_PACKET packet = tagged UMF_PACKET_dataChunk chunk;

            readBuffers[currentReadChannel].enq(packet);

            // increment chunks read
            readChunksRemaining <= readChunksRemaining - 1;

        end

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
        // small number of channels

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

        // start new write message
        rule write_physical_channel_newmsg (ready == 1 && grant[i]);

            // get header packet
            UMF_PACKET packet = writeBuffers[i].first();
            writeBuffers[i].deq();

            // create and encode header chunk, TODO: generalize
            UMF_CHUNK headerChunk = 0;

            case (packet) matches

                tagged UMF_PACKET_header .h:
                begin
                    headerChunk[31:28] = fromInteger(i);
                    headerChunk[27:20] = truncate(h.serviceID);
                    headerChunk[19:16] = truncate(h.methodID);
                    headerChunk[15:0]  = truncate(h.length);
                end

                default:
                    noAction; // shouldn't happen

            endcase

            // send the header chunk to the physical channel
            cio_write(handle, pack(headerChunk));

            // setup remaining chunks
            UMF_MSG_LENGTH totalchunks = packet.UMF_PACKET_header.length >> `UMF_CHUNK_LOG_BYTES;

            if ((totalchunks & (`UMF_CHUNK_BITS - 1)) != 0)
                writeChunksRemaining <= totalchunks;
            else
                writeChunksRemaining <= totalchunks - 1;

            currentWriteChannel <= fromInteger(i);

        endrule

    end // for

    // continue writing message
    rule write_physical_channel_continue (ready == 1 && writeChunksRemaining != 0);

        // get the next packet from the active write channel
        UMF_PACKET packet = writeBuffers[currentWriteChannel].first();
        writeBuffers[currentWriteChannel].deq();

        // extract chunk
        UMF_CHUNK chunk = case (packet) matches
                              tagged UMF_PACKET_dataChunk .d: d;
                              default                       : ?; // shouldn't happen
                          endcase;

        // send the data chunk to the physical channel
        cio_write(handle, pack(chunk));

        // one more chunk processed
        writeChunksRemaining <= writeChunksRemaining - 1;

    endrule

    // ==============================================================
    //                          Interfaces
    // ==============================================================

    interface readPorts = rports;
    interface writePorts = wports;

endmodule
