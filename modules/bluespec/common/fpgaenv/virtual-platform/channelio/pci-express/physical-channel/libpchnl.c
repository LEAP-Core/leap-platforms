#include "libpchnl.h"

/**
 * pchnl_open_channel - open the Hardware Channel
 * @pchnl: HW channel struct
 *
 * pchnl_open_channel should be called before any other functions
 * to perform operation via HW Channel. This function
 * initialize a hw_channel structure to be used in other
 * rountines in the library.
 *
 * pchnl_open_channel returns 0 if successfully open the channel,
 * returns negative if failure.
 **/
int pchnl_open_channel(struct hw_channel *pchnl)
{
    if (pchnl == NULL){
        LIB_PCHNL_ALERT("invalid channel parameter\n");
        return -ECHANNEL;
    }

    pchnl->fd = open("/dev/pchnl", O_RDWR);
    if (pchnl->fd < 0){
        LIB_PCHNL_ALERT("error opening device\n");
        return -ENODEVICE;
    }

    return 0;
}

/**
 * pchnl_close_channel - close the Hardware Channel
 * @pchnl: HW channel struct
 *
 * pchnl_close_channel should be called after any other functions
 * to perform operation via HW Channel. This function
 * finalize the hw_channel structure and release
 * corresponding resources.
 *
 * pchnl_close_channel returns 0 if successfully open the channel,
 * returns negative if failure.
 **/
int pchnl_close_channel(struct hw_channel *pchnl)
{
     int ret = 0;

     if (pchnl == NULL){
          LIB_PCHNL_ALERT("invalid channel parameter");
          ret = -ECHANNEL;
          goto err;
     }
     
     close(pchnl->fd);
err:
     return ret;
}

/**
 * pchnl_read_csr_comm - Read Common CSR
 * @pchnl: HW channel struct
 * @idx: The CSR index to be read, should be ranged from
         0 to (COMM_CSR_COUNT - 1)
 * @pval: The value returned by the func call
 *
 * pchnl_read_csr_comm read CSR with index specified, it returns value
 * by the last parameter.
 *
 * pchnl_read_csr_comm returns 0 if successfully open the channel,
 * returns negative if failure.
 **/
int pchnl_read_csr_comm(struct hw_channel *pchnl, unsigned int idx, unsigned int *pval)
{
     struct pchnl_req req;
     int ret = 0;
     if ( pchnl == NULL){
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     if ( idx >= COMM_CSR_COUNT ){
          LIB_PCHNL_ALERT("CSR index overflow\n");
          ret = -EOVERFLOW;
          goto failed;
     }
     

     req.u.tranx_csr.idx = idx;
     if (ioctl(pchnl->fd, PCHNL_CSR_READ, &req) == -1){
          LIB_PCHNL_ALERT("read csr failed\n");
          ret = -ECSRREAD;
          goto failed;
     }
     *pval = req.u.tranx_csr.val;
failed:
     return ret;
}

/**
 * pchnl_write_csr_comm - Write Common CSR
 * @pchnl: HW channel struct
 * @idx: The CSR index to be written, should be ranged from
         0 to (COMM_CSR_COUNT - 1)
 * @val: The value to be written
 *
 * pchnl_write_csr_comm write CSR with index and value specified
 *
 * pchnl_read_csr_comm returns 0 if successfully open the channel,
 * returns negative if failure.
 **/
int pchnl_write_csr_comm(struct hw_channel *pchnl, unsigned int idx, unsigned int val)
{
     struct pchnl_req req;
     int ret = 0;

     if ( pchnl == NULL){
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     if ( idx >= COMM_CSR_COUNT ){
          LIB_PCHNL_ALERT("CSR index overflow\n");
          ret = -EOVERFLOW;
          goto failed;
     }
          

     req.u.tranx_csr.idx = idx;
     req.u.tranx_csr.val = val;
     if ( ioctl(pchnl->fd, PCHNL_CSR_WRITE, &req) == -1){
          LIB_PCHNL_ALERT("write csr failed\n");
          ret = -ECSRWRITE;
          goto failed;
     }
failed:
     return ret;
}
     
int pchnl_write_csr_sys(struct hw_channel *pchnl, unsigned int val)
{
     int ret = 0;
     struct pchnl_req req;

     if ( pchnl == NULL) {
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     req.u.tranx_sys_csr.val = val;
     if ( ioctl(pchnl->fd, PCHNL_SYS_CSR_WRITE, &req) == -1) {
          LIB_PCHNL_ALERT("write sys csr failed\n");
          ret = -ECSRWRITE;
          goto failed;
     }
failed:
     return ret;
}

int pchnl_read_csr_sys(struct hw_channel *pchnl, unsigned int *pval)
{
     int ret = 0;
     struct pchnl_req req;

     if ( pchnl == NULL ) {
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     if ( ioctl(pchnl->fd, PCHNL_SYS_CSR_READ, &req) == -1){
          LIB_PCHNL_ALERT("read sys csr failed\n");
          ret = -ECSRREAD;
          goto failed;
     }
     *pval = req.u.tranx_sys_csr.val;
failed:
     return ret;
}
     

/**
 * pchnl_csr_tester - do a CSR test with a demo SPL
 * @pchnl: HW channel struct
 * @idx: csr index in the test
 * @val: csr value in the test
 *
 * pchnl_csr_tester start a CSR test with a demo SPL.
 * More detailed, demo SPL will write to CSR with index specified by csr_index
 * and value specified by csr_value, then demo SPL read the same csr out and store
 * the value in a internal register (even more detailed information can be found in
 * the src file of demo SPL named SPL_CSR_TESTER.vhd in HDL project).
 *
 * pchnl_csr_tester returns 0 if successfully perform the test,
 * returns negative if failure.
 **/
int pchnl_csr_tester(struct hw_channel *pchnl, unsigned int idx, unsigned int val)
{
     struct pchnl_req req;
     int ret = 0;

     if (pchnl == NULL){
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     if ( idx >= COMM_CSR_COUNT) {
          LIB_PCHNL_ALERT("CSR index overflow\n");
          ret = -EOVERFLOW;
          goto failed;
     }

     req.u.tranx_csr_tester.idx = idx;
     req.u.tranx_csr_tester.val = val;
     if ( ioctl(pchnl->fd, PCHNL_CSR_TESTER, &req) == -1) {
          LIB_PCHNL_ALERT("test failed\n");
          ret = -ECSRTEST;
          goto failed;
     }
failed:
     return ret;
}

int pchnl_intr_tester(struct hw_channel *pchnl)
{
     struct pchnl_req req;
     int ret = 0;

     if (pchnl == NULL){
          LIB_PCHNL_ALERT("no channel specified\n");
          ret = -ECHANNEL;
          goto failed;
     }

     if ( ioctl(pchnl->fd, PCHNL_INTR_TESTER, &req) == -1) {
          LIB_PCHNL_ALERT("test failed\n");
          ret = -ECSRTEST;
          goto failed;
     }
failed:
     return ret;
}
