#include <iostream>

#include "sim-channelio.h"
#include "basic-rrr-client.h"

#define CHANNEL_ID  1

using namespace std;

// constructor
RRR_CLIENT_CLASS::RRR_CLIENT_CLASS(
    HASIM_MODULE p,
    CHANNELIO cio)
{
    parent = p;
    channelio = cio;
}

// destructor
RRR_CLIENT_CLASS::~RRR_CLIENT_CLASS()
{
}

// make request with response
UMF_MESSAGE
RRR_CLIENT_CLASS::MakeRequest(
    UMF_MESSAGE request)
{
    // add channelID to request
    request->SetChannelID(CHANNEL_ID);

    // write request message to channelio
    channelio->Write(CHANNEL_ID, request);

    // read response (blocking read) from channelio
    UMF_MESSAGE response = channelio->Read(CHANNEL_ID);

    return response;
}

// make request with no response
void
RRR_CLIENT_CLASS::MakeRequestNoResponse(
    UMF_MESSAGE request)
{
    // add channelID to request
    request->SetChannelID(CHANNEL_ID);

    // write request message to channelio
    channelio->Write(CHANNEL_ID, request);
}
