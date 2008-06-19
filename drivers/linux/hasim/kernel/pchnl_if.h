#ifndef __PCHNL_IF_H__
#define __PCHNL_IF_H__

#ifndef __BEGIN_DECLS
#ifdef __cplusplus
#define __BEGIN_DECLS extern "C" {
#define __END_DECLS }
#else
#define __BEGIN_DECLS
#define __END_DECLS
#endif
#endif

__BEGIN_DECLS

#ifndef __KERNEL__
#include <sys/types.h>
#include <sys/ioctl.h>
#include <stdint.h>
#define __user
#endif

#define COMM_CSR_COUNT 256
#define CSR_REGION_SIZE (1uL << 13)
#define COMM_CSR_BASE_OFFSET ( 1uL << 12)
#define SYS_CSR_BASE_OFFSET (0)

struct pchnl_req
{
     union {
          /* csr read/write transaction */
          struct{
               uint32_t idx;
               uint32_t val;
          } tranx_csr;
          struct{
               uint32_t val;
          } tranx_sys_csr;
          struct{
               uint32_t idx;
               uint32_t val;
          }tranx_csr_tester;
          struct{
               uint32_t len;
               void *datap;
               uint32_t loop_count;
          }tranx_dma;
          struct{
               uint32_t h2f_len;
               void *h2f_datap;
               uint32_t f2h_len;
               void *f2h_datap;
               uint32_t loop_count;
          }tranx_dma_duplex;
          struct{
               unsigned int * intr_reg_p;
          }tranx_set_intr_reg;
          struct{
               uint32_t misc;
          }tranx_intr_tester;
     } u;
};

#define PCHNL_CSR_READ _IOR('x', 0x00, struct pchnl_req)
#define PCHNL_CSR_WRITE _IOW('x', 0x01, struct pchnl_req)
#define PCHNL_CSR_TESTER _IOW('x', 0x02, struct pchnl_req)          
#define PCHNL_SYS_CSR_WRITE _IOW('x', 0x03, struct pchnl_req)
#define PCHNL_SYS_CSR_READ _IOR('x', 0x04, struct pchnl_req)
#define PCHNL_INTR_TESTER _IOW('x', 0x05, struct pchnl_req)
#define PCHNL_DMA_H2F _IOW('x', 0x06, struct pchnl_req)
#define PCHNL_DMA_F2H _IOR('x', 0x07, struct pchnl_req)
#define PCHNL_SET_INTR_REG _IOW('x', 0x08, struct pchnl_req)
#define PCHNL_DMA_DUPLEX _IOW('x', 0x09, struct pchnl_req)
#define PCHNL_RESET _IOW('x', 0x0a, struct pchnl_req)
__END_DECLS

#endif
