#include <iostream>

#include "basic-rrr-client.h"

#define CHANNEL_ID  1

using namespace std;

// global link
RRR_CLIENT RRRClient;

// constructor
RRR_CLIENT_CLASS::RRR_CLIENT_CLASS(
    PLATFORMS_MODULE p,
    CHANNELIO    cio) :
        PLATFORMS_MODULE_CLASS(p)
{
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

    //cout << "client: received response" << endl;
    //response->Print(cout);

    return response;
}

// make request with no response
void
RRR_CLIENT_CLASS::MakeRequestNoResponse(
    UMF_MESSAGE request)
{
    // add channelID to request
    request->SetChannelID(CHANNEL_ID);

    //cout << "client: making request, need response" << endl;
    //request->Print(cout);

    // write request message to channelio
    channelio->Write(CHANNEL_ID, request);
}
