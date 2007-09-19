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
typedef void   (*InitFunction)    (int ID, char *stringID);
typedef void   (*MainFunction)    (void);
typedef bool   (*ServiceFunction) (UINT32, UINT32, UINT32, UINT32 *);
typedef void   (*UninitFunction)  (void);

typedef struct _Service
{
    int                 ID;             /* unique service ID */
    char                stringID[256];  /* unique string ID */
    int                 params;         /* number of UINT32 parameters */
    InitFunction        init;           /* init function */
    MainFunction        main;           /* main function */
    ServiceFunction     request;        /* service function */
    UninitFunction      uninit;         /* uninit */
} Service;

typedef struct _GlobalArgs
{
    char    benchmark[256];
} GlobalArgs;

extern GlobalArgs   globalArgs;

void server_callback_exit(int serviceID, int exitcode);

#endif
