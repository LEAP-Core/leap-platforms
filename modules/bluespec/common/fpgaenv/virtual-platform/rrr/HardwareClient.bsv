`include "channelio.bsh"
`include "rrr_common.bsh"

`define CLIENT_CHANNEL_ID 0

interface RRRClient;
    method Action                       makeRequest(RRR_Request request);
    method ActionValue#(RRR_Response)   getResponse();
endinterface

typedef enum
{
    CLIENT_STATE_ready,
    CLIENT_STATE_sendParam1,
    CLIENT_STATE_sendParam2,
    CLIENT_STATE_readResponseHeader,
    CLIENT_STATE_readResponseData,
    CLIENT_STATE_responseReady
}
CLIENT_STATE
    deriving (Bits, Eq);

module mkRRRClient#(ChannelIO channel) (RRRClient);

    Reg#(CLIENT_STATE)  state           <- mkReg(CLIENT_STATE_ready);
    Reg#(Bit#(32))      param1Buffer    <- mkReg(0);
    Reg#(Bit#(32))      param2Buffer    <- mkReg(0);
    Reg#(Bit#(32))      responseBuffer  <- mkReg(0);
    Reg#(Bool)          needResponse    <- mkReg(False);

    rule send_param1(state == CLIENT_STATE_sendParam1);
        UMF_PACKET packet = tagged UMF_PACKET_dataChunk param1Buffer;
        channel.writePorts[`CLIENT_CHANNEL_ID].write(packet);
        state <= CLIENT_STATE_sendParam2;
    endrule

    rule send_param2(state == CLIENT_STATE_sendParam2);
        UMF_PACKET packet = tagged UMF_PACKET_dataChunk param2Buffer;
        channel.writePorts[`CLIENT_CHANNEL_ID].write(packet);
        if (needResponse)
            state <= CLIENT_STATE_readResponseHeader;
        else
            state <= CLIENT_STATE_ready;
    endrule

    rule read_response_header(state == CLIENT_STATE_readResponseHeader);
        UMF_PACKET response <- channel.readPorts[`CLIENT_CHANNEL_ID].read();
        // ignore header
        state <= CLIENT_STATE_readResponseData;
    endrule

    rule read_response_data(state == CLIENT_STATE_readResponseData);
        UMF_PACKET response <- channel.readPorts[`CLIENT_CHANNEL_ID].read();
        responseBuffer <= pack(response.UMF_PACKET_dataChunk);
        state <= CLIENT_STATE_responseReady;
    endrule

    method Action makeRequest(RRR_Request request) if (state == CLIENT_STATE_ready);
        // generate header and send to channelio
        UMF_PACKET hdrpacket =  tagged UMF_PACKET_header
                                {
                                    channelID: `CLIENT_CHANNEL_ID,
                                    serviceID: request.serviceID,
                                    methodID : truncate(pack(request.param0)),
                                    length   : 8
                                };
                                    
        channel.writePorts[`CLIENT_CHANNEL_ID].write(hdrpacket);

        // buffer params
        param1Buffer <= request.param1;
        param2Buffer <= request.param2;
        needResponse <= request.needResponse;

        state <= CLIENT_STATE_sendParam1;
    endmethod

    method ActionValue#(RRR_Response) getResponse() if (state == CLIENT_STATE_responseReady);
        state <= CLIENT_STATE_ready;
        return responseBuffer;
    endmethod

endmodule
