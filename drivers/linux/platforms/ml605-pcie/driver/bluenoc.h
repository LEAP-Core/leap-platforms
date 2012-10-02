#ifndef __BLUENOC_H__
#define __BLUENOC_H__

#include <linux/ioctl.h>

/*
 * IOCTLs
 */

/* magic number for IOCTLs */
#define BNOC_IOC_MAGIC 0xB5

/* Structures used with IOCTLs */

typedef struct {
  unsigned int       board_number;
  unsigned int       is_active;
  unsigned int       major_rev;
  unsigned int       minor_rev;
  unsigned int       build;
  unsigned int       timestamp;
  unsigned int       bytes_per_beat;
  unsigned long long content_id;
} tBoardInfo;

/* IOCTL code definitions */

#define BNOC_IDENTIFY   _IOR(BNOC_IOC_MAGIC,0,tBoardInfo*)
#define BNOC_SOFT_RESET _IO(BNOC_IOC_MAGIC,1)
#define BNOC_DEACTIVATE _IO(BNOC_IOC_MAGIC,2)
#define BNOC_REACTIVATE _IO(BNOC_IOC_MAGIC,3)

/* maximum valid IOCTL number */
#define BNOC_IOC_MAXNR 3

#endif /* __BLUENOC_H__ */
