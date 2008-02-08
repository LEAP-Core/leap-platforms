#ifndef _LIB_PCHNL_H
#define _LIB_PCHNL_H

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>

#include "pchnl_if.h"

#ifdef LIBDBG
#define LIB_PCHNL_ALERT(args...) printf(args)
#else
#define LIB_PCHNL_ALERT(args...)
#endif

/* error code */
#define ECHANNEL 1
#define EOVERFLOW 2
#define ENOMEM 3
#define ENODEVICE 4
#define ECSRREAD 5
#define ECSRWRITE 6
#define ECSRTEST 7

struct hw_channel
{
     int fd;
};

int pchnl_open_channel(struct hw_channel *pchnl);
int pchnl_close_channel(struct hw_channel *pchnl);

/************** Common CSR Access ****************/
int pchnl_read_csr_comm(struct hw_channel *pchnl, unsigned int csr_index, unsigned int * pcsr_value);
int pchnl_write_csr_comm(struct hw_channel *pchnl, unsigned int csr_index, unsigned int csr_value);

/************** System CSR Access ***************/
//temporarily unavailable
int pchnl_read_csr_sys(struct hw_channel *pchnl, unsigned int *pcsr_value);
int pchnl_write_csr_sys(struct hw_channel *pchnl, unsigned int csr_value);

/************** Tester *********************/
int pchnl_csr_tester(struct hw_channel *pchnl, unsigned int csr_index, unsigned int csr_value);
int pchnl_intr_tester(struct hw_channel *pchnl);


#endif
