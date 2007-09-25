#ifndef __SOFTWARE_RRR_SERVER__
#define __SOFTWARE_RRR_SERVER__

#define CHANNELIO_PACKET_SIZE   4
#define STDIN                   0
#define STDOUT                  1
#define MAX_SERVICES            128
#define MAX_ARGS                3

#define CHANNELIO_HOST_2_FPGA   100
#define CHANNELIO_FPGA_2_HOST   101

typedef unsigned int UINT32;

typedef class RRR_SERVICE_CLASS* RRR_SERVICE;
class RRR_SERVICE_CLASS
{
    protected:
        int     serviceID;      /* unique service ID */
        char    stringID[256];  /* unique string ID */
        int     params;         /* number of UINT32 parameters */

    public:
        virtual void    Init(int ID)                                = 0;
        virtual void    Uninit()                                    = 0;
        virtual bool    Request(UINT32, UINT32, UINT32, UINT32 *)   = 0;
        virtual void    Clock(void)                                 = 0;
};

void rrr_server_init();
void rrr_server_uninit();
void rrr_server_clock();
void server_callback_exit(int serviceID, int exitcode);

#endif
