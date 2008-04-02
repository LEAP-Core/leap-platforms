#ifndef __SIM_CHANNELIO__
#define __SIM_CHANNELIO__

#include <queue>
#include "hasim-module.h"
#include "asim/provides/umf.h"
#include "asim/provides/physical_channel.h"

using namespace std;

#define CIO_NUM_CHANNELS    2

// ============================================
//       Base Class for Message Receivers
// ============================================

typedef class CIO_DELIVERY_STATION_CLASS* CIO_DELIVERY_STATION;
class CIO_DELIVERY_STATION_CLASS
{
    public:
        virtual void DeliverMessage(UMF_MESSAGE) = 0;
};

// ============================================
//             Channel I/O Station
// ============================================

enum CIO_STATION_TYPE
{
    CIO_STATION_TYPE_READ,
    CIO_STATION_TYPE_DELIVERY
};

struct CIO_STATION_INFO
{
    // type of reads the station does (read/delivery)
    CIO_STATION_TYPE        type;

    // link to module (only required for interrupt-type stations)
    CIO_DELIVERY_STATION    module;

    // buffers
    queue<UMF_MESSAGE>  readBuffer;
};

// ============================================
//                 Channel I/O                 
// ============================================

typedef class CHANNELIO_CLASS* CHANNELIO;
class CHANNELIO_CLASS:  public HASIM_MODULE_CLASS
{
    private:
        // physical channel instance
        PHYSICAL_CHANNEL_CLASS  physicalChannel;

        // stations attached to virtual channels
        CIO_STATION_INFO    stations[CIO_NUM_CHANNELS];

    public:
        CHANNELIO_CLASS(HASIM_MODULE, PHYSICAL_DEVICES);
        ~CHANNELIO_CLASS();

        void        RegisterForDelivery(int, CIO_DELIVERY_STATION);
        UMF_MESSAGE Read(int);
        void        Write(int, UMF_MESSAGE);
        void        Poll();
};

#endif
