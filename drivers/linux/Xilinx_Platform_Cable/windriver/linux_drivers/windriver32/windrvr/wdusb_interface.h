#ifndef _WDUSB_INTERFACE_H_
#define _WDUSB_INTERFACE_H_

#if defined(__cplusplus)
    extern "C" {
#endif
#if defined(LINUX)
typedef struct semaphore *XEVENT;

#endif  

typedef struct _trans_t
{
    struct _trans_t *next;
    struct pipe_t *pipe;
    void *os_trans_ctx;
    void (*os_trans_ctx_destroy_cb)(void *);
    BOOL is_halted;
    long refcnt;
} trans_t;

typedef struct
{
    /* Internal buffer */
    PBYTE buffer;
    DWORD curr_ptr;
    DWORD curr_count;

    HANDLE file_h;
    void *requests;
    BOOL is_running;
    os_spinlock_t spinlock;
    void *os_trans_ctx;
    void *action_timer;

    /* Set by user */
    WDU_STREAM settings;
} stream_t;

typedef struct pipe_t 
{
    HANDLE handle;
    trans_t *trans_list;
    BOOL trans_active;
    os_spinlock_t trans_spinlock;
    UCHAR endpoint_address;
    UCHAR attributes;
    USHORT max_packet_size;  
    UCHAR interval;
    DWORD max_urb_transfer_size;
    stream_t *stream;
} pipe_t;

typedef struct _stream_context_t
{
    DWORD di_unique_id;
    DWORD pipe_num;
} stream_context_t;

DWORD Usb_device_attach(HANDLE os_dev_h, DWORD interface_num,
    DWORD configuration_value);

DWORD Usb_device_detach(HANDLE os_dev_h);

DWORD OS_register_devices(void **register_ctx, WDU_MATCH_TABLE *match_tables, 
    DWORD match_tabs_number);
DWORD OS_unregister_devices(void *register_handle);
DWORD OS_get_device_property(HANDLE os_dev_h, void *buf, DWORD *buf_size, 
    WD_DEVICE_REGISTRY_PROPERTY prop);
DWORD OS_get_device_info(HANDLE os_dev_h, void *buf, 
    DWORD *buf_size, DWORD active_config, DWORD active_interface, 
    DWORD active_setting, BOOL is_kernelmode, DWORD dwOptions);
DWORD OS_set_interface(HANDLE os_dev_h, 
    WDU_ALTERNATE_SETTING **alt_setting_info, 
    DWORD interface_num, DWORD alternate_setting);
DWORD OS_get_max_urb_transfer_size(BOOL high_speed, const pipe_t *pipe);
DWORD OS_open_pipe(HANDLE os_dev_h, 
    const WDU_ENDPOINT_DESCRIPTOR *endpoint_desc, pipe_t *pipe);
DWORD OS_close_device(HANDLE os_dev_h);
DWORD OS_reset_pipe(HANDLE os_dev_h, pipe_t *pipe);
DWORD OS_transfer(HANDLE os_dev_h, pipe_t *pipe, HANDLE file_h,
    PRCHANDLE prc_h, DWORD is_read, DWORD options, PVOID buf, DWORD bytes,
    DWORD *bytes_transferred, BYTE *setup_packet, DWORD timeout,
    PVOID ioctl_context);
DWORD OS_stream_transfer_create(HANDLE os_dev_h, pipe_t *pipe);
DWORD OS_stream_transfer_start(stream_t *stream);
DWORD OS_stream_transfer_stop(stream_t *stream);
DWORD OS_stream_transfer_flush(stream_t *stream);
DWORD OS_stream_transfer_close(stream_t *stream);
DWORD OS_halt_transfer(void *os_trans_ctx);
BOOL OS_init(void);
void OS_uninit(void);
DWORD OS_wakeup(HANDLE os_dev_h, DWORD options);
DWORD OS_reset_device(HANDLE os_dev_h, DWORD options);
DWORD OS_selective_suspend(HANDLE os_dev_h, DWORD options);

trans_t *create_transfer(pipe_t *pipe, void *os_trans_ctx, void (*os_trans_ctx_destroy_cb)(void *));
BOOL release_transfer(trans_t *trans);
void addref_transfer(trans_t *trans);

const char *get_pipe_type(pipe_t *pipe);

HANDLE buf_init(void *buf_addr);
void *buf_malloc(HANDLE h, DWORD size);
void *buf_uninit(HANDLE h);

DWORD Usb_fix_map_device(KPTR buf_addr, KPTR user_addr);
stream_context_t* OS_get_stream_context(HANDLE file_h);
void OS_set_stream_context(HANDLE file_h, stream_context_t *context);

DWORD Usb_stream_read(HANDLE file_h, PBYTE buf, DWORD bytes, void *request,
    DWORD *bytes_transfered, BOOL *pending);
DWORD Usb_stream_write(HANDLE file_h, PBYTE buf, DWORD bytes, void *request,
    DWORD *bytes_transfered, BOOL *pending);
DWORD OS_stream_request_insert(stream_t *stream, void *request);
BOOL OS_is_stream_requests_queue_empty(stream_t *stream);
void OS_stream_action_timer_cb(void *ctx);

DWORD stream_buffer_out(stream_t *stream, PBYTE user_buffer, 
    DWORD bytes, DWORD *bytes_transferred);
DWORD stream_buffer_in(stream_t *stream, PBYTE user_buffer, 
    DWORD bytes);

#ifdef __cplusplus
}
#endif

#endif

