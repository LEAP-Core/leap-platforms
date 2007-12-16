#ifndef __BASIC_RRR_CLIENT__
#define __BASIC_RRR_CLIENT__

#include "sim-channelio.h"

typedef class RRR_CLIENT_CLASS* RRR_CLIENT;

class RRR_CLIENT_CLASS: public HASIM_MODULE_CLASS
{
    private:
        // link to channelio
        CHANNELIO   channelio;

    public:
        RRR_CLIENT_CLASS(HASIM_MODULE, CHANNELIO);
        ~RRR_CLIENT_CLASS();

        UMF_MESSAGE MakeRequest(UMF_MESSAGE);
        void MakeRequestNoResponse(UMF_MESSAGE);
};

#endif
