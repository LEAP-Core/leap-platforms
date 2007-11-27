import FIFO::*;
import Vector::*;

`include "toplevel_wires.bsh"

`define CIO_NUM_READ_CHANNELS   2
`define CIO_NUM_WRITE_CHANNELS  2

`define CIO_DECODE_MSGLENGTH(chunk) chunk[15:0]
`define CIO_DECODE_CID(chunk)       chunk[31:28]
`define CIO_CID_BITS                4
`define CIO_CHUNK_SIZE              4
`define CIO_LOG_CHUNK_SIZE          2

`define POLL_INTERVAL   0

typedef Bit#(16) CIO_MsgLength;
typedef Bit#(4)  CIO_ChannelID;
typedef Bit#(32) CIO_Chunk;

// BDPI imports
import "BDPI" function Action                 cio_init();
import "BDPI" function ActionValue#(Bit#(8))  cio_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(64)) cio_read(Bit#(8) handle);
import "BDPI" function Action   cio_write(Bit#(8) handle, Bit#(32) data);

// read/write port interfaces
interface CIOReadPort;
    method ActionValue#(CIO_Chunk) read();
endinterface

interface CIOWritePort;
    method Action write(CIO_Chunk data);
endinterface

// channelio interface
interface ChannelIO;
    interface Vector#(`CIO_NUM_READ_CHANNELS, CIOReadPort)   readPorts;
    interface Vector#(`CIO_NUM_WRITE_CHANNELS, CIOWritePort) writePorts;
endinterface

// channelio module
module mkChannelIO#(TopLevelWiresDriver wires) (ChannelIO);

    Reg#(Bit#(8))   handle              <- mkReg(0);
    Reg#(Bit#(2))   ready               <- mkReg(0);
    Reg#(Bit#(32))  pollCounter         <- mkReg(0);
    Reg#(Bit#(32))  chunksRemaining     <- mkReg(0);
    Reg#(Bit#(8))   currentReadChannel  <- mkReg(0);

    // create read buffers and link them to read ports
    FIFO#(CIO_Chunk)                                readBuffers[`CIO_NUM_READ_CHANNELS];
    Vector#(`CIO_NUM_READ_CHANNELS, CIOReadPort)    rports = newVector();

    for (Integer i = 0; i < `CIO_NUM_READ_CHANNELS; i = i+1)
    begin
        readBuffers[i] <- mkFIFO();

        // create a new read port and link it to the FIFO
        rports[i] = interface CIOReadPort
                        method ActionValue#(CIO_Chunk) read();

                            CIO_Chunk val = readBuffers[i].first();
                            readBuffers[i].deq();
                            return val;

                        endmethod
                    endinterface;
    end

    // create write buffers and link them to write ports
    FIFO#(CIO_Chunk)                                writeBuffers[`CIO_NUM_WRITE_CHANNELS];
    Vector#(`CIO_NUM_WRITE_CHANNELS, CIOWritePort)  wports = newVector();

    for (Integer i = 0; i < `CIO_NUM_WRITE_CHANNELS; i = i+1)
    begin
        writeBuffers[i] <- mkFIFO();

        // create a new write port and link it to the FIFO
        wports[i] = interface CIOWritePort
                        method Action write(CIO_Chunk data);

                            writeBuffers[i].enq(data);

                        endmethod
                    endinterface;
    end

    // --- rules --- //

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

    /*
    // probe C code for incoming new message header
    rule read_physical_channel_newmsg (ready == 1       &&
                                       pollCounter == 0 &&
                                       chunksRemaining == 0);

        Bit#(64) data <- cio_read(handle);

        // 0xFFFFFFFF00000000 implies "no data"
        if (data != 'hFFFFFFFF00000000)
        begin
            CIO_Chunk chunk = data[`CIO_CHUNK_SIZE*8 - 1 : 0];

            // decode message length and channel ID
            CIO_MsgLength len = `CIO_DECODE_MSGLENGTH(chunk);
            CIO_ChannelID cid = `CIO_DECODE_CID(chunk);

            // expunge the channelID from the header
            CIO_Chunk lengthmask = zeroExtend(len);
            CIO_Chunk newchunk = (chunk << `CIO_CID_BITS) | lengthmask;

            // enqueue the new header into the channel's FIFO
            readBuffers[cid].enq(newchunk);

            // setup channel for remaining chunks
            Bit#(32) totalchunks = zeroExtend(len) >> `CIO_LOG_CHUNK_SIZE;
            if ((totalchunks & (`CIO_CHUNK_SIZE*8 - 1)) != 0)
                chunksRemaining <= totalchunks;
            else
                chunksRemaining <= totalchunks - 1;
            currentReadChannel <= zeroExtend(cid);
        end

    endrule

    // probe C code for incoming read data (continuing old message)
    rule read_physical_channel_contmsg (ready == 1           &&
                                        pollCounter == 0     &&
                                        chunksRemaining != 0);

        Bit#(64) data <- cio_read(handle);

        // 0xFFFFFFFF00000000 implies "no data"
        if (data != 'hFFFFFFFF00000000)
        begin
            CIO_Chunk chunk = data[`CIO_CHUNK_SIZE*8 - 1 : 0];
            readBuffers[currentReadChannel].enq(chunk);
        end

        // increment chunks read
        chunksRemaining <= chunksRemaining - 1;

    endrule
    */

    // ***** temporary rules to emulate old behavior of channelIO *****
    rule temp_read_physical_channels(ready == 1 && pollCounter == 0);

        Bit#(64) data <- cio_read(handle);

        // 0xFFFFFFFF00000000 implies "no data"
        if (data != 'hFFFFFFFF00000000)
        begin
            CIO_Chunk chunk = data[`CIO_CHUNK_SIZE*8 - 1 : 0];
            readBuffers[0].enq(chunk);
        end

    endrule

    rule temp_write_physical_channels(ready == 1 && pollCounter == 0);

        CIO_Chunk chunk = writeBuffers[0].first();
        writeBuffers[0].deq();
        cio_write(handle, pack(chunk));

    endrule
    // ***** end temporary rules *****

    // --- interfaces --- //
    interface readPorts = rports;
    interface writePorts = wports;

endmodule
