/* 
 * Source file for WinDriver Linux.
 *
 * This file may be distributed only as part of the 
 * application you are distributing, and only if it 
 * significantly contributes to the functionality of your 
 * application. (see \windriver\docs\license.txt for details).
 *
 * Web site: http://www.jungo.com
 * Email:    support@jungo.com
 *
 * (C) Jungo 1999 - 2007
 */

#include "linux_common.h"
#if defined(LINUX_24_26)
    #include <linux/compiler.h>
#endif
#include <linux/pci.h>
#include <linux/init.h>
#include <linux/ioport.h>
#if defined(LINUX_24_26)
    #include <linux/completion.h>
    #include <linux/interrupt.h>
    #include <linux/mm.h>
#endif
#include <linux/sched.h>
#include <linux/pagemap.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <asm/delay.h>
#if defined(LINUX_26)
    #include <asm/cacheflush.h>
    #include <linux/efi.h>
#endif
#if defined(LINUX_24)
    #include <linux/iobuf.h>
#endif
#if defined(LINUX_24_26)
    #include <linux/vmalloc.h>
#endif
#if defined(LINUX_20_22)
    #include <linux/malloc.h>
#endif
#include <asm/mman.h>
#include "linux_wrappers.h"
#if defined(LINUX_26)
    #include <linux/ioctl32.h>
#endif
#if defined(UDEV_SUPPORT)
    #include <linux/devfs_fs_kernel.h>
#endif

#if defined(WINDRIVER_KERNEL)
    #if !defined(WD_DRIVER_NAME_CHANGE)
        /* For backward compatability reasons, the windrvr6 module
         * needs to export WD_register_kp_module */
        unsigned int WD_register_kp_module(char*, void *, void*);
    #endif
#endif

#if defined(WINDRIVER_KERNEL)
    #define REGISTER_FUNC_MOD static
#else
    /* When building the kernel plugin */
    #define REGISTER_FUNC_MOD extern
#endif
         
#if defined(WD_DRIVER_NAME_CHANGE)
    REGISTER_FUNC_MOD LINUX_wd_register_kp_module_func %DRIVER_NAME%_register_kp_module_func;
#else
    REGISTER_FUNC_MOD LINUX_wd_register_kp_module_func WD_register_kp_module_func;
#endif

#if defined(WINDRIVER_KERNEL) && (defined(LINUX_22_24_26))
    #define EXPORT_SYMTAB
#endif
#include <linux/module.h> // must come after #define EXPORT_SYMTAB

#if defined(MODVERSIONS)
    #include <linux/modversions.h>
#endif

#if defined(WINDRIVER_KERNEL) && defined(LINUX_20)
    #undef MODVERSIONS
    static struct symbol_table export_syms = {
        #include <linux/symtab_begin.h>
        X(WD_register_kp_module),
        #include <linux/symtab_end.h>
    };
#endif

#if defined(MODULE_LICENSE)
    MODULE_LICENSE("Proprietary");
#endif
#if defined(MODULE_AUTHOR)
    MODULE_AUTHOR("Jungo");
#endif
#if defined(MODULE_DESCRIPTION)
    #include "wd_ver.h"
    MODULE_DESCRIPTION("WinDriver v" WD_VERSION_STR " Jungo (C) 1999 - 2007");
#endif

#if defined(LINUX_22_24_26)
    void generic_pci_remove(void *dev_h, int notify);
    int generic_pci_probe(void *dev_h, int notify);
#else
    #include <linux/bios32.h>
#endif

#if defined(CONFIG_SWIOTLB) || defined(IA64)
    #define _CONFIG_SWIOTLB
#endif

#if defined(LINUX_24_26)
    #define VM_PG_OFFSET(vma) (vma)->vm_pgoff
    #define VM_BYTE_OFFSET(vma) ((vma)->vm_pgoff << PAGE_SHIFT)
#else
    #define VM_PG_OFFSET(vma) (vma)->vm_offset 
    #define VM_BYTE_OFFSET(vma) ((vma)->vm_offset << PAGE_SHIFT)
#endif

#define PAGE_COUNT(buf,size) ((((unsigned long)buf & ~PAGE_MASK) + size + ~PAGE_MASK) >> PAGE_SHIFT)

#if defined(LINUX_24_26)
    static struct pci_dev *pci_root_dev;
#endif

static inline int is_high_memory(unsigned long addr)
{
    return (addr >= (unsigned long)high_memory);
}

static inline int is_high_memory_phys(unsigned long phys_addr)
{
    return (phys_addr >= (unsigned long)virt_to_phys(high_memory));
}

int LINUX_down_interruptible(struct semaphore *sem)
{
    return down_interruptible(sem);
}

void LINUX_up(struct semaphore *sem)
{
    up(sem);
}

struct semaphore *LINUX_create_mutex(void)
{
    struct semaphore *sem = (struct semaphore *) kmalloc(sizeof(struct
        semaphore), GFP_ATOMIC);

#if defined(LINUX_24_26)
    init_MUTEX(sem);
#else
    memset(sem,0,sizeof(struct semaphore));
#if defined(LINUX_22)
    atomic_set(&sem->count,1);
#else
    sem->count = 1;
#endif
#endif
    return sem;
}

void LINUX_free_mutex(struct semaphore *sem)
{
    kfree(sem);
}

void *LINUX_vmalloc(unsigned long size)
{
    return (void *) vmalloc(size);
}

void LINUX_vfree(void *addr)
{
    vfree(addr);
}

void *LINUX_kmalloc(unsigned int size, int flag)
{
    if (size > 128*1024)
        return NULL;
    flag |= flag & ATOMIC ? GFP_ATOMIC : GFP_KERNEL;
    flag |= flag & DMA ? GFP_DMA : 0;
    return kmalloc((size_t) size, flag);
}

void *LINUX_dma_contig_alloc(unsigned int size, int flag)
{
#if defined(LINUX_24_26)
    int gfp = ((flag & DMA) ? GFP_DMA : 0);
    #if defined(LINUX_26)
        gfp |= __GFP_NOWARN; 
    #if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,6)
        gfp |= __GFP_COMP;
    #endif
    #endif
    return (void *)__get_free_pages(gfp, get_order(size));
#else
    return LINUX_kmalloc(size, flag);
#endif
}

void LINUX_dma_contig_free(void *va, unsigned int size)
{
#if defined(LINUX_24_26)
    free_pages((unsigned long)va, get_order(size));
#else
    kfree(va);
#endif
}

void LINUX_kfree(const void *addr)
{
    kfree(addr);
}

unsigned long LINUX_copy_from_user(void *to, const void *from, unsigned long n)
{
    unsigned long rc = 0;
    #if defined(LINUX_26)
        rc = copy_from_user(to, from, n);
    #elif defined(LINUX_20)
        memcpy_fromfs(to, from, n);
    #elif defined(LINUX_22) || defined(LINUX_24)
        memcpy(to, from, n);
    #endif
    return rc;
}

unsigned long LINUX_copy_to_user(void *to, const void *from, unsigned long n)
{
    unsigned long rc = 0;
    #if defined(LINUX_26)
        rc = copy_to_user(to, from, n);
    #elif defined(LINUX_20)
        memcpy_tofs(to, from ,n);
    #elif defined(LINUX_22) || defined(LINUX_24)
        memcpy(to, from, n);
    #endif
    return rc;
}

void LINUX_MOD_INC_USE_COUNT(void)
{
#if !defined(LINUX_26)
    MOD_INC_USE_COUNT;
#endif
}

void LINUX_MOD_DEC_USE_COUNT(void)
{
#if !defined(LINUX_26)
    MOD_DEC_USE_COUNT;
#endif
}

#if defined(LINUX_26)
struct page *windriver_vma_nopage(struct vm_area_struct *vma,
    unsigned long address, int *type) 
#elif defined(LINUX_24)
struct page *windriver_vma_nopage(struct vm_area_struct *vma,
    unsigned long address, int unused) 
#else
unsigned long windriver_vma_nopage(struct vm_area_struct *vma,
    unsigned long address, int unused) 
#endif
{
    unsigned long off = address - vma->vm_start;
    unsigned long va = (unsigned long)vma->vm_private_data + off;
    
#if defined(LINUX_24_26)
    struct page *page;
    
    page = virt_to_page((void *)va);
    get_page(page); /* increment page count */

    #if defined(LINUX_26)
    if (type)
        *type = VM_FAULT_MINOR;
    #endif
    return page; 
#else
    atomic_inc(&mem_map[MAP_NR(__pa(va))].count);
    return __pa(va);
#endif
}

struct vm_operations_struct windriver_vm_ops = {
    nopage:     windriver_vma_nopage,
};

#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,9)
    #define REMAP_PAGE_RANGE remap_page_range
    #define REMAP_OFFSET(vma) VM_BYTE_OFFSET(vma)
#else
    #define REMAP_PAGE_RANGE remap_pfn_range
    #define REMAP_OFFSET(vma) VM_PG_OFFSET(vma)
#endif

#if defined(REMAP_API_CHANGE) || defined(LINUX_26)
    #define REMAP_ARG(vma) vma,
#else
    #define REMAP_ARG(vma) 
#endif

#ifndef pgprot_noncached /* define only for architectures supported by windriver */
#if defined(POWERPC) || defined(PPC64)
   #define pgprot_noncached(prot) (__pgprot(pgprot_val(prot) | _PAGE_NO_CACHE | _PAGE_GUARDED))
#elif defined(IA64)
   #define pgprot_noncached(prot) (__pgprot((pgprot_val(prot) & ~_PAGE_MA_MASK) | _PAGE_MA_UC))
#elif defined(__x86_64__)
   #define pgprot_noncached(prot) (__pgprot(pgprot_val(prot) | _PAGE_PCD | _PAGE_PWT))
#elif defined(__i386__)
   #define pgprot_noncached(prot) \
        (boot_cpu_data.x86 > 3 ? __pgprot(pgprot_val(prot) | _PAGE_PCD | _PAGE_PWT) : prot)
#endif 
#endif

#if defined(__i386__)
#ifndef cpu_has_mtrr
   #define cpu_has_mtrr (test_bit(X86_FEATURE_MTRR, boot_cpu_data.x86_capability))
#endif
#ifndef cpu_has_k6_mtrr
   #define cpu_has_k6_mtrr (test_bit(X86_FEATURE_K6_MTRR, boot_cpu_data.x86_capability))
#endif
#ifndef cpu_has_cyrix_arr
   #define cpu_has_cyrix_arr (test_bit(X86_FEATURE_CYRIX_ARR, boot_cpu_data.x86_capability))    
#endif
#ifndef cpu_has_centaur_mcr
   #define cpu_has_centaur_mcr (test_bit(X86_FEATURE_CENTAUR_MCR, boot_cpu_data.x86_capability))        
#endif                                                                                
#endif

#if defined(LINUX_24_26)
    static inline int uncached_access(struct file *file, unsigned long addr)
    {
    #if defined(__i386__)
        if (file->f_flags & O_SYNC)
                return 1;
        return !(cpu_has_mtrr || cpu_has_k6_mtrr || cpu_has_cyrix_arr ||
            cpu_has_centaur_mcr) && (addr >= __pa(high_memory));
    #elif defined(__x86_64__)
        if (file->f_flags & O_SYNC)
                return 1;
        return 0;
    #elif defined(CONFIG_IA64)
        #if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,11)
        return !(efi_mem_attributes(addr) & EFI_MEMORY_WB);
        #else
        return 1;
        #endif
    #elif defined(CONFIG_PPC64)
        return !page_is_ram(addr >> PAGE_SHIFT);
    #else
        if (file->f_flags & O_SYNC)
                return 1;
        return addr >= __pa(high_memory);
    #endif
    }
#else
    #define uncached_access(file, addr) 1
#endif

static int wd_mmap(
    #if defined(LINUX_20)
    struct inode *inode,
    #endif 
    struct file *file, struct vm_area_struct *vma)
{
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,4,14)
    vma->vm_flags |= VM_SHM | VM_LOCKED; /* don't swap out */
#else
    vma->vm_flags |= VM_RESERVED; /* don't swap out */
#endif

    if (file->private_data)
    {
        /* map DMA buffer */
        vma->vm_file = file;
        vma->vm_private_data = file->private_data; 
        vma->vm_ops = &windriver_vm_ops; /* use "nopage" method for system memory */
    }
    else
    {
        /* map IO buffer */
        vma->vm_flags |= VM_IO;
        if (uncached_access(file, VM_BYTE_OFFSET(vma)))
            vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);

        if (REMAP_PAGE_RANGE(
            REMAP_ARG(vma) vma->vm_start, REMAP_OFFSET(vma), vma->vm_end - vma->vm_start, vma->vm_page_prot))
        {
            return -EAGAIN;
        }
    #if defined(LINUX_20)
        vma->vm_inode = inode;
        inode->i_count++;
    #endif
    }
    return 0;
}

#if defined(WINDRIVER_KERNEL)
    #if defined(LINUX_20)
    void WDlinuxClose_20(struct inode *inode, struct file *filp)
    {
        WDlinuxClose(inode, filp);
    }
    #endif

    #if defined(CONFIG_COMPAT) && !defined(IA64)
        #if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,13)
            static int LINUX_ioctl_compat(unsigned int fd, unsigned int cmd,
                unsigned long arg, struct file *filep) 
        #else
            static long LINUX_ioctl_compat(struct file *filep, unsigned int cmd,
                unsigned long arg)
        #endif
            {
                struct inode *inode = filep->f_dentry->d_inode;
                return wd_linux_ioctl_compat(inode, filep, cmd, arg);
            }
    #endif

    #if defined(LINUX_24) && defined(CONFIG_COMPAT) && !defined(IA64)
    extern int register_ioctl32_conversion(unsigned int cmd,
        int (*handler)(unsigned int, unsigned int, unsigned long, struct file *));
    extern int unregister_ioctl32_conversion(unsigned int cmd);
    #endif

    int LINUX_register_ioctl32_conversion(unsigned int cmd)
    {
    #if defined(CONFIG_COMPAT) && !defined(IA64)
        #if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,13)
            return register_ioctl32_conversion(cmd, LINUX_ioctl_compat);
        #else
            return 0;
        #endif
    #else
        return -EINVAL;
    #endif
    }

    int LINUX_unregister_ioctl32_conversion(unsigned int cmd)
    {
    #if defined(CONFIG_COMPAT) && !defined(IA64)
        #if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,13)
            return unregister_ioctl32_conversion(cmd);
        #else
            return 0;
        #endif
    #else
        return -EINVAL;
    #endif
    }

    struct file_operations windriver_fops = {
        #if defined(LINUX_24_26)
            owner: THIS_MODULE,
        #endif
        ioctl: WDlinuxIoctl,
        mmap: wd_mmap,
        open: WDlinuxOpen,
        #if defined(LINUX_22_24_26)
            release: WDlinuxClose,
        #else
            release: WDlinuxClose_20,
        #endif
        #if defined(CONFIG_COMPAT) && (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,13))
            compat_ioctl: LINUX_ioctl_compat,
        #endif
    };

#if defined(UDEV_SUPPORT)
    static struct class_simple *windrvr_class = NULL;
#endif
    int LINUX_register_chrdev(unsigned int major, const char *name)
    {
#if defined(UDEV_SUPPORT)
        int err, new_major;

        new_major = register_chrdev(major, name, &windriver_fops);
        if (new_major < 0)
            return new_major;

        windrvr_class = class_simple_create(THIS_MODULE, (char*)name);
        if (IS_ERR(windrvr_class)) 
        {
            err = PTR_ERR(windrvr_class);
            printk("WinDriver: failed to create class (%d)\n", err);
            goto Error;
        }
        class_simple_device_add(windrvr_class, MKDEV(new_major, 0), NULL, name);
        err = devfs_mk_cdev(MKDEV(new_major, 0), S_IFCHR|S_IRUSR|S_IWUSR, 
            name);
        if (err)
        {
            printk("WinDriver: failed to make devfs node (%d)\n", err);
            goto Error;
        }
        return new_major;

Error:
        if (windrvr_class)
        {
            class_simple_device_remove(MKDEV(new_major,0));
            class_simple_destroy(windrvr_class);
        }
        unregister_chrdev(new_major, name);
        return err;
#else
        return register_chrdev(major, name, &windriver_fops);
#endif
    }
    
    int LINUX_unregister_chrdev(unsigned int major, const char *name)
    {
#if defined(UDEV_SUPPORT)
        devfs_remove(name);
        class_simple_device_remove(MKDEV(major, 0));
        class_simple_destroy(windrvr_class);
#endif
        return unregister_chrdev(major, name);
    }
#endif

const char *LINUX_get_driver_name(void)
{
#if defined(WD_DRIVER_NAME_CHANGE)
    /* This section should only be compiled when building the
     * wizard generated kernel module */
    return "%DRIVER_NAME%";
#else
    return "windrvr6";
#endif
}

LINUX_wd_register_kp_module_func LINUX_get_register_kp_module_func(void)
{
#if defined(WD_DRIVER_NAME_CHANGE)
    return %DRIVER_NAME%_register_kp_module_func;
#else
    return WD_register_kp_module_func;
#endif
}

void LINUX_set_register_kp_module_func(LINUX_wd_register_kp_module_func func)
{
#if defined(WD_DRIVER_NAME_CHANGE)
    %DRIVER_NAME%_register_kp_module_func = func;
#else
    WD_register_kp_module_func = func;
#endif
}

#if !defined(WINDRIVER_KERNEL)
void LINUX_kp_inc_ref_count(void)
{
#if defined(LINUX_26)
    try_module_get(THIS_MODULE);
#else
    MOD_INC_USE_COUNT;
#endif
}

void LINUX_kp_dec_ref_count(void)
{
#if defined(LINUX_26)
    module_put(THIS_MODULE);
#else
    MOD_DEC_USE_COUNT;
#endif
}
#endif

void *LINUX_bh_alloc(void (*routine)(void *), void *data)
{
#if defined(LINUX_26)
    struct work_struct *bh = (struct work_struct*) vmalloc(sizeof(*bh));
#else
    struct tq_struct *bh = (struct tq_struct *) vmalloc(sizeof(*bh));
#endif
    if (!bh)
        return NULL;
    memset(bh, 0, sizeof(*bh));
    bh->data = data;
#if defined(LINUX_26)
    bh->func = routine;
    bh->entry.next = &bh->entry;
    bh->entry.prev = &bh->entry;
#else
    bh->routine = routine;
#endif
    return (void *)bh;
}

void LINUX_bh_free(void *bh)
{
    vfree(bh);
}

void LINUX_flush_scheduled_tasks(void)
{
#if defined(LINUX_26)
    flush_scheduled_work();
#elif defined(LINUX_24)
    flush_scheduled_tasks();
#else
    // not used
#endif

}

void LINUX_schedule_task(void *bh)
{
#if defined(LINUX_26)
    schedule_work(bh);
#elif defined(LINUX_24)
    schedule_task(bh);
#else
    queue_task(bh, &tq_scheduler);
#endif
}

struct int_wrapper
{
    struct int_wrapper *next;
    void *ctx;
    int (*handler)(void *);
};

struct int_data_t
{
    struct int_wrapper *c_list;
    spinlock_t lock;

};

static struct int_data_t int_data = 
{
    .lock = SPIN_LOCK_UNLOCKED
};

#if defined(LINUX_26)
irqreturn_t
#else
void
#endif
wrapper_handler(int irq, void *ctx, struct pt_regs *pt)
{
    struct int_wrapper *context = (struct int_wrapper *)ctx;
    int rc = 0;
    if (context && context->handler)
        rc = context->handler(context->ctx);
#if defined(LINUX_26)
    return rc;
#endif
}

int LINUX_request_irq(unsigned int irq, int (*handler)(void *),
    int is_shared, const char *device, void *ctx)
{
    unsigned long flags = SA_INTERRUPT;
    struct int_wrapper *c;
    int rc;
    c = kmalloc(sizeof(struct int_wrapper), GFP_KERNEL);
        
    if (!c)
        return -ENOMEM;
    c->handler = handler;
    c->ctx = ctx;
    if (is_shared)
        flags |= SA_SHIRQ;
    rc = request_irq(irq, wrapper_handler, flags, device, c);
    if (rc)
        kfree(c);
    else 
    {
        spin_lock_irq(&int_data.lock);
        c->next = int_data.c_list;
        int_data.c_list = c;
        spin_unlock_irq(&int_data.lock);
    }
    return rc;
}

void LINUX_free_irq(unsigned int irq, void *ctx)
{
    struct int_wrapper **c;
    struct int_wrapper *tmp = NULL;

    spin_lock_irq(&int_data.lock);
    for (c = &int_data.c_list; *c; c = &(*c)->next)
    {
        if ((*c)->ctx == ctx)
        {
            tmp = *c;
            *c = (*c)->next;
            break;
        }
    }
    spin_unlock_irq(&int_data.lock);

    if (tmp)
    {
        free_irq(irq, tmp);
        kfree(tmp);
    }
}

unsigned long LINUX_ioremap (unsigned long phys_addr, unsigned long size)
{
#if !defined(IA64)
    if (is_high_memory_phys(phys_addr))
    {
#endif
    #if defined(LINUX_22_24_26)
        return (unsigned long)ioremap_nocache(phys_addr, size);
    #else
        return (unsigned long)vremap(phys_addr, size);
    #endif
#if !defined(IA64)
    }
    else if (!is_high_memory_phys(phys_addr + size - 1))
        return (unsigned long)phys_to_virt(phys_addr);

    return 0;
#endif
}

void LINUX_iounmap(unsigned long addr)
{
#if !defined(IA64)
    if (!is_high_memory(addr))
        return;
#endif
    
#if defined(LINUX_22_24_26)
    iounmap((void *)addr);
#else
    vfree((void *)addr);
#endif
}

unsigned long LINUX_do_mmap(struct file *file, 
    unsigned long len, unsigned long phys_addr, void *kernel_addr)
{
    unsigned long addr;

#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,4,2)
    down(&current->mm->mmap_sem);
#else
    down_write(&current->mm->mmap_sem);
#endif    
    /* when kernel address is not zero, this is a mapping of DMA buffer */
    file->private_data = kernel_addr;
    addr = do_mmap(file, 0, len, PROT_READ | PROT_WRITE, MAP_SHARED, phys_addr);
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,4,2)
    up(&current->mm->mmap_sem);
#else
    up_write(&current->mm->mmap_sem);
#endif
    return addr;
}

int LINUX_do_munmap(unsigned long addr, unsigned int len)
{
    return do_munmap(
#if defined(LINUX_24_26)           
        current->mm,
#endif
        addr, (size_t) len
#if defined(DO_MUNMAP_API_CHANGE)
        , 0
#endif
        );
}

int LINUX_pcibios_present(void)
{
#if defined(LINUX_20_22) 
    return pcibios_present();
#else
    return 1;   
#endif
}

#define GET_CUR_DEV(bus, dev_fn) \
    struct pci_dev *dev; \
    unsigned char old_bus=0; \
    unsigned char old_devfn=0; \
    int rc; \
    int fake = 0; \
    dev = pci_find_slot(bus, dev_fn); \
    if (!dev) \
    { \
        fake = 1; \
        dev = pci_root_dev; \
        old_bus = dev->bus->number; \
        old_devfn = dev->devfn; \
        dev->bus->number = bus; \
        dev->devfn = dev_fn; \
    }

#define UNGET_CUR_DEV \
    if (fake) \
    { \
        dev->bus->number = old_bus; \
        dev->devfn = old_devfn; \
    } \

    
int LINUX_pcibios_read_config_byte (unsigned char bus, unsigned char dev_fn,
                  unsigned char where, unsigned char *val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_read_config_byte(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_read_config_byte(bus, dev_fn, where, val); 
#endif
}

int LINUX_pcibios_read_config_word (unsigned char bus, unsigned char dev_fn,
                  unsigned char where, unsigned short *val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_read_config_word(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_read_config_word(bus, dev_fn, where, val);
#endif
}

int LINUX_pcibios_read_config_dword (unsigned char bus, unsigned char dev_fn,
                  unsigned char where, unsigned int *val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_read_config_dword(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_read_config_dword(bus, dev_fn, where, val);
#endif
}

int LINUX_pcibios_write_config_byte (unsigned char bus, unsigned char dev_fn,
                   unsigned char where, unsigned char val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_write_config_byte(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_write_config_byte(bus, dev_fn, where, val);
#endif
}

int LINUX_pcibios_write_config_word (unsigned char bus, unsigned char dev_fn,
                   unsigned char where, unsigned short val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_write_config_word(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_write_config_word(bus, dev_fn, where, val);
#endif
}

int LINUX_pcibios_write_config_dword (unsigned char bus, unsigned char dev_fn,
                   unsigned char where, unsigned int val)
{
#if defined(LINUX_24_26)
    GET_CUR_DEV(bus, dev_fn);
    rc = pci_write_config_dword(dev, where, val);
    UNGET_CUR_DEV;
    return rc;
#else
    return pcibios_write_config_dword(bus, dev_fn, where, val);
#endif
}

void LINUX_udelay(unsigned long usecs)
{
    udelay(usecs);
}

void LINUX_schedule(void)
{
    schedule();
}

long LINUX_schedule_timeout(long timeout)
{
    set_current_state(TASK_INTERRUPTIBLE);
    return schedule_timeout(timeout);
}

#if defined(WINDRIVER_KERNEL)
    void LINUX_register_windriver_symboles()
    {
        #if defined(LINUX_20)
            register_symtab(&export_syms);
        #endif
    }
    #if defined(LINUX_26)
        #if defined(WD_DRIVER_NAME_CHANGE)
             EXPORT_SYMBOL(%DRIVER_NAME%_register_kp_module_func);
        #else
             EXPORT_SYMBOL(WD_register_kp_module);
             EXPORT_SYMBOL(WD_register_kp_module_func);
        #endif
    #elif defined(LINUX_22) || defined(LINUX_24)
        #if defined(WD_DRIVER_NAME_CHANGE)
             EXPORT_SYMBOL_NOVERS(%DRIVER_NAME%_register_kp_module_func);
        #else 
             EXPORT_SYMBOL_NOVERS(WD_register_kp_module);
             EXPORT_SYMBOL_NOVERS(WD_register_kp_module_func);
        #endif
    #endif
#endif

void LINUX_register_symboles()
{
    #if defined(LINUX_20)
        register_symtab(NULL);
    #elif defined(LINUX_24)
        EXPORT_NO_SYMBOLS;
    #endif
}

#if defined(LINUX_24_26) && defined(WINDRIVER_KERNEL)
#include <linux/init.h>

#if defined(WD_DRIVER_NAME_CHANGE)
    #define WD_PCI_DRIVER_NAME "%DRIVER_NAME%_pci"
#else
    #define WD_PCI_DRIVER_NAME "windrvr6_pci"
#endif

static int __devinit wrap_generic_pci_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
    generic_pci_probe(dev, 0);
    return -ENODEV;
}

static void __devexit wrap_generic_pci_remove(struct pci_dev *dev)
{
    generic_pci_remove(dev, 0);
}

void LINUX_pci_get_pnp_data(void *dev_h, LINUX_pnp_data *p)
{
    struct pci_dev *dev = (struct pci_dev *)dev_h;
    p->irq = dev->irq;
    p->devfn = dev->devfn;
    p->bus_num = dev->bus->number;
    p->dev_h = dev;
    p->vid = dev->vendor;
    p->did = dev->device;
    p->hdr_type = dev->hdr_type;
}

void LINUX_pci_set_irq(void *dev_h, unsigned char irq)
{
    struct pci_dev *dev = (struct pci_dev *)dev_h;
    dev->irq = irq;
}
    
static const struct pci_device_id all_pci_ids[] = { {

        /* we want monitoring all devices */
        vendor:         PCI_ANY_ID,
        device:         PCI_ANY_ID,
        subvendor:      PCI_ANY_ID,
        subdevice:      PCI_ANY_ID,

        }, { /* end: all zeroes */ }
};

MODULE_DEVICE_TABLE (pci, all_pci_ids);

static struct pci_driver generic_pci_driver = {
        name:           WD_PCI_DRIVER_NAME,
        id_table:       &all_pci_ids [0],

        probe:          wrap_generic_pci_probe,
        remove:         wrap_generic_pci_remove,

};

#endif

int init_module(void) 
{
#if defined(LINUX_24_26)
    int ret;
    
    ret = init_module_cpp();
    if (ret)
    {
        printk("init module failed status: %d\n", ret);
        return ret;
    }
     
    pci_root_dev = pci_find_device(PCI_ANY_ID, PCI_ANY_ID, NULL);
    if (!pci_root_dev)
    {
        printk("windrvr error: unable to obtain pci_root_dev\n");
        return -1;
    }

    #if defined(WINDRIVER_KERNEL)
        pci_module_init(&generic_pci_driver);
    #endif
    return 0;
#endif
    return init_module_cpp();
}

void cleanup_module(void) 
{
#if defined(LINUX_26) && defined(WINDRIVER_KERNEL)
    pci_unregister_driver(&generic_pci_driver);
#endif
    cleanup_module_cpp();
}

unsigned int LINUX_get_version(void)
{
#if defined(LINUX_20)
    return 200;
#elif defined(LINUX_22)
    return 220;
#elif defined(LINUX_24)
    return 240;
#elif LINUX_VERSION_CODE < KERNEL_VERSION(2,6,6)
    return 260;
#else
    return 266;
#endif
}

unsigned int LINUX_need_copy_from_user(void)
{
#if defined(LINUX_20) || defined(LINUX_26)
    return 1;
#else
    return 0;
#endif
}

struct semaphore *LINUX_create_semaphore(void)
{
    struct semaphore *sem = (struct semaphore *) kmalloc(sizeof(struct
        semaphore), GFP_ATOMIC);
#if defined(LINUX_24_26)
    sema_init(sem, 0);
#else
    memset(sem,0,sizeof(struct semaphore));
#endif
    return sem;
}

void LINUX_free_semaphore(struct semaphore *sem)
{
    kfree((void *)sem);
}

unsigned long LINUX_jiffies()
{
    return jiffies;
}

long LINUX_get_time_in_sec()
{
    struct timeval tv;
    do_gettimeofday(&tv);
    return tv.tv_sec;
}

#if defined LINUX_20_22
int LINUX_printk(const char *fmt, ...)
{
    int p[12];
    int res;
    int i;
    va_list args;
    va_start(args, fmt);
    for (i=0; i<sizeof(p)/sizeof(*p); i++)
        p[i] = va_arg(args, int);
    res = printk(fmt, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]);
    va_end(args);
    return res;
}
#else
int LINUX_printk(const char *fmt, ...)
{
    static char p[1024];
    va_list ap;
    int n;
    va_start(ap, fmt);
    n = vsnprintf (p, 1024, fmt, ap);
    va_end(ap);
    printk(p);
    return n; 
}
#endif

int LINUX_sprintf(char *buf, const char *fmt, ...)
{
    int res;
    va_list args;
    va_start(args, fmt);
    res = vsprintf(buf, fmt, args);
    va_end(args);
    return res; 
}

int LINUX_snprintf(char *buf, unsigned long n, const char *fmt, ...)
{
    int res;
    va_list args;
    va_start(args, fmt);
#if defined(LINUX_24_26)
    res = vsnprintf(buf, n, fmt, args);
#else
    res = vsprintf(buf, fmt, args);
#endif
    va_end(args);
    return res;
}
    
int LINUX_vsprintf(char *buf, const char *fmt, va_list args)
{
    return vsprintf(buf, fmt, args);
}

int LINUX_vsnprintf(char *buf, unsigned long n, const char *fmt, va_list args)
{
#if defined(LINUX_24_26)
    return vsnprintf(buf, n, fmt, args);
#else
    return vsprintf(buf, fmt, args);
#endif
}

unsigned long LINUX_virt_to_phys(void *va)
{
    return virt_to_phys(va);
}

_u64 LINUX_pci_map_single(void *dev, void *va, unsigned long size,
    unsigned int dma_direction)
{
    dma_addr_t pa = pci_map_single(dev, va, size, (int)dma_direction);
#if defined(dma_mapping_error)
    if (pci_dma_mapping_error(pa))
#else
    if (!pa)
#endif
    {
        printk("%s: failed, va %p, pa %llx, size %lx\n", __FUNCTION__, va,
            (_u64)pa, size);
        pa = 0;
    }
    return (_u64)pa;
}

void LINUX_pci_unmap_single(void *dev, _u64 pa, unsigned long size,
    unsigned int dma_direction)
{
    pci_unmap_single(dev, (dma_addr_t)pa, size, (int)dma_direction);
}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,4,0)
    #define pci_dma_sync_single_for_cpu(x...)
    #define pci_dma_sync_sg_for_cpu(x...)
    #define pci_dma_sync_single_for_device(x...)
    #define pci_dma_sync_sg_for_device(x...)
#elif LINUX_VERSION_CODE < KERNEL_VERSION(2,6,5)
    #define pci_dma_sync_single_for_cpu pci_dma_sync_single
    #define pci_dma_sync_sg_for_cpu pci_dma_sync_sg
    #define pci_dma_sync_single_for_device(x...)
    #define pci_dma_sync_sg_for_device(x...)
#endif

void LINUX_pci_dma_sync_single_for_cpu(void *dev, _u64 dma_addr,
    unsigned long size, unsigned int dma_direction)
{
    pci_dma_sync_single_for_cpu(dev, (dma_addr_t)dma_addr, size, (int)dma_direction);
}

void LINUX_pci_dma_sync_single_for_device(void *dev, _u64 dma_addr,
    unsigned long size, unsigned int dma_direction)
{
    pci_dma_sync_single_for_device(dev, (dma_addr_t)dma_addr, size,
        (int)dma_direction);
}

void LINUX_pci_dma_sync_sg_for_cpu(void *dev, void *dma_handle, int nelems,
    unsigned int dma_direction)
{
#if !defined(_CONFIG_SWIOTLB)
    pci_dma_sync_sg_for_cpu(dev, dma_handle, nelems, (int)dma_direction);
#else
    struct scatterlist *sgl = (struct scatterlist *)dma_handle;
    int i;
    for (i=0; i<nelems; i++)
        pci_dma_sync_single_for_cpu(dev, sg_dma_address(&sgl[i]), sg_dma_len(&sgl[i]), (int)dma_direction);
#endif
}

void LINUX_pci_dma_sync_sg_for_device(void *dev, void *dma_handle, int nelems,
    unsigned int dma_direction)
{
#if !defined(_CONFIG_SWIOTLB)
    pci_dma_sync_sg_for_device(dev, dma_handle, nelems, (int)dma_direction);
#else
    struct scatterlist *sgl = (struct scatterlist *)dma_handle;
    int i;
    for (i=0; i<nelems; i++)
        pci_dma_sync_single_for_device(dev, sg_dma_address(&sgl[i]), sg_dma_len(&sgl[i]), (int)dma_direction);
#endif
}

int LINUX_pci_set_dma_mask(void *dev, _u64 dma_mask)
{
#if defined(LINUX_24_26)
    return pci_set_dma_mask(dev, dma_mask);     
#else
    return 0;
#endif
}

void LINUX_mem_map_reserve(void *addr, unsigned long size)
{
    struct page *page;

    if (!addr || !size)
        return;

    for (page = virt_to_page(addr); page <= virt_to_page(addr + size - 1); page++)
#if defined(LINUX_24_26)
        SetPageReserved(page);
#else
        set_bit(PG_reserved, &page->flags);
#endif
}
    
void LINUX_mem_map_unreserve(void *addr, unsigned long size)
{
    struct page *page;

    if (!addr || !size)
        return;

    for (page = virt_to_page(addr); page <= virt_to_page(addr + size - 1); page++)
#if defined(LINUX_24_26)
        ClearPageReserved(page);
#else
        clear_bit(PG_reserved, &page->flags);
#endif
}

unsigned long LINUX_usecs_to_jiffies(unsigned long usecs)
{
    struct timespec t;
    t.tv_sec = usecs / 1000000L;
    t.tv_nsec = (usecs - t.tv_sec * 1000000L) * 1000L;
    return timespec_to_jiffies(&t);
}

unsigned long LINUX_msecs_to_jiffies(unsigned long msecs)
{
    struct timespec t;
    t.tv_sec = msecs / 1000L;
    t.tv_nsec = (msecs - t.tv_sec * 1000L) * 1000000L;
    return timespec_to_jiffies(&t);
}

void LINUX_add_timer(struct timer_list *timer, unsigned long timeout_msecs)
{
    timer->expires = jiffies + LINUX_msecs_to_jiffies(timeout_msecs);
    add_timer(timer);
}

void LINUX_create_timer(struct timer_list **timer, 
    void (*timer_cb)(unsigned long), unsigned long ctx)
{
    *timer = vmalloc(sizeof(struct timer_list));
    init_timer(*timer);
    (*timer)->function = timer_cb;
    (*timer)->data = ctx;
}

void LINUX_del_timer(struct timer_list *timer)
{
    del_timer(timer);
}

void LINUX_destroy_timer(struct timer_list *timer)
{
    vfree(timer);
}

void LINUX_spin_lock_irqsave(os_spinlock_t *lock)
{
    spin_lock_irqsave((spinlock_t *)lock->spinlock, lock->flags);
}

void LINUX_spin_unlock_irqrestore(os_spinlock_t *lock)
{
    spin_unlock_irqrestore((spinlock_t *)lock->spinlock, lock->flags);
}

void LINUX_spin_lock_irq(os_spinlock_t *lock)
{
    spin_lock_irq((spinlock_t *)lock->spinlock);
}

void LINUX_spin_unlock_irq(os_spinlock_t *lock)
{
    spin_unlock_irq((spinlock_t *)lock->spinlock);
}

void LINUX_spin_lock_init(os_spinlock_t *lock)
{
    spinlock_t *sl;
    // adding 4 bytes since sizeof(spinlock_t) can be zero
    sl = kmalloc(sizeof(spinlock_t)+4, GFP_ATOMIC);
    spin_lock_init(sl);
    lock->spinlock = (void *)sl;
}

void LINUX_spin_lock_uninit(os_spinlock_t *lock)
{
    kfree(lock->spinlock);
    lock->spinlock = NULL;
}

#if defined(LINUX_26)
static int build_dma_list_26(LINUX_dma_page *page_list, void *buf, unsigned long size,
    unsigned int *dma_sglen, unsigned int dma_direction, void *dev_handle, void **dma_handle)
{
    int rc, res = 0, i;
    struct page **pages = NULL;
    struct scatterlist *sgl;
    unsigned int page_count = *dma_sglen;
#if defined(_CONFIG_SWIOTLB)
    dma_addr_t mask;
#endif

    *dma_sglen = 0;
    if (!(sgl = vmalloc(sizeof(struct scatterlist) * page_count)))
    {
        rc = -ENOMEM;
        goto Error;
    }

    if (!(pages = kmalloc(page_count * sizeof(*pages), GFP_KERNEL)))
    {
        rc= -ENOMEM;
        goto Error;
    }

    /* Try to fault in all of the necessary pages */
    down_read(&current->mm->mmap_sem);
    
    res = get_user_pages( current, current->mm, (unsigned long)buf, page_count,
        1, /* read/write permission */
        1, /* force: only require the 'MAY' flag, e.g. allow "write" even to readonly page */
        pages,
        NULL);

    up_read(&current->mm->mmap_sem);

    if (res != page_count)
    {
        rc = -EINVAL;
        goto Error;
    }

    memset (sgl, 0, sizeof(struct scatterlist) * page_count);
    sgl[0].offset = ((unsigned long)buf) & (~PAGE_MASK);
    sgl[0].page = pages[0]; 
    if (page_count > 1)
    {
        sgl[0].length = PAGE_SIZE - sgl[0].offset;
        size -= sgl[0].length;
        for (i=1; i < page_count ; i++, size -= PAGE_SIZE) 
        {
            sgl[i].page = pages[i]; 
            sgl[i].length = size < PAGE_SIZE ? size : PAGE_SIZE;
        }
    }
    else
        sgl[0].length = size;


    /* map sglist, dma_sglen <= page_count */
#if defined(_CONFIG_SWIOTLB)
    *dma_sglen = page_count;
    mask = dev_handle ? ((struct pci_dev *)dev_handle)->dma_mask : (dma_addr_t)-1;
#else
    *dma_sglen = pci_map_sg((struct pci_dev *)dev_handle, sgl, page_count,
        (int)dma_direction);
#endif
    if (!(*dma_sglen))
    {
        rc = -ENXIO;
        goto Error;
    }

    for (i=0; i<*dma_sglen; i++)
    {
#if defined(_CONFIG_SWIOTLB)
        void *va = page_address(sgl[i].page) + sgl[i].offset;
        dma_addr_t dma_addr = virt_to_phys(va);
        
        if (dma_addr & ~mask)
            dma_addr = pci_map_single(dev_handle, va, sgl[i].length, (int)dma_direction);
            
        sg_dma_address(&sgl[i]) = dma_addr;
        sg_dma_len(&sgl[i]) = sgl[i].length;
#endif
        page_list[i].phys = sg_dma_address(&sgl[i]);
        page_list[i].size = sg_dma_len(&sgl[i]);
    }
    kfree(pages);
    *dma_handle = sgl;
    return 0;

 Error:
    printk("%s: error %d\n", __FUNCTION__, rc);
    for (i=0; i < res; i++)
    {
        if (!PageReserved(pages[i]))
            SetPageDirty(pages[i]);
        page_cache_release(pages[i]);
    }
    if (pages)
        kfree(pages);
    if (sgl)
        vfree(sgl);

    return rc;
}
#endif

#if defined(LINUX_24)
static int build_dma_list_24(LINUX_dma_page *page_list, void *buf, 
    unsigned long size, unsigned int dma_direction, void *dev_handle, void **dma_handle)
{
    int rc, i;
    struct kiobuf *iobuf;
#if defined(KIOBUF_WITH_SIZE)
    int nbhs = KIO_MAX_SECTORS;
    rc = alloc_kiovec_sz(1, &iobuf ,&nbhs);
#else
    rc = alloc_kiovec(1, &iobuf);
#endif

    if (rc)
    {
        printk("failed allocate iobuf\n");
        goto Error;
    }

    rc = map_user_kiobuf(READ, iobuf, (unsigned long) buf, size);
    if (rc)
    {
        printk("failed lock user buffer %p, size %ld, dma_direction %x\n", 
            buf, size, dma_direction);
        goto Error;
    }

    for (i=0; i<iobuf->nr_pages; i++)
    {
        page_list[i].phys = (iobuf->maplist[i] - mem_map) * PAGE_SIZE;
        page_list[i].size = PAGE_SIZE; 
    }
    *dma_handle= iobuf;
    return 0;

Error:
#if defined(KIOBUF_WITH_SIZE)
    free_kiovec_sz(1, &iobuf, &nbhs);
#else
    free_kiovec(1, &iobuf);
#endif
    return rc;

}
#endif

int LINUX_build_sg_dma(LINUX_dma_page *page_list, unsigned int *dma_sglen, 
    void *buf, unsigned long size, unsigned int dma_direction, void *dev_handle, 
    void **dma_handle)
{
    unsigned int page_count = PAGE_COUNT(buf, size);
    int rc = 0;

#if defined(LINUX_26)
    rc = build_dma_list_26(page_list, buf, size, &page_count, (int)dma_direction, dev_handle,
        dma_handle);
#elif defined(LINUX_24)
    rc = build_dma_list_24(page_list, buf, size, (int)dma_direction, dev_handle, 
        dma_handle);
#else
    // Not suppored by older kernels
    rc = 0x2000000aL;
#endif 
    if (!rc)
        *dma_sglen = page_count;
    return rc;
}

int LINUX_free_sg_dma(void *dma_handle, void *buf, unsigned long size,
    unsigned int dma_direction, void *dev_handle)
{
#if defined(LINUX_26)
    int i;
    unsigned int page_count = PAGE_COUNT(buf, size);
    struct scatterlist *sgl = (struct scatterlist *)dma_handle;
    
#if !defined(_CONFIG_SWIOTLB)
    pci_unmap_sg((struct pci_dev *)dev_handle, sgl, page_count, (int)dma_direction);
#endif
    
    for (i=0; i < page_count; i++) 
    {
#if defined(_CONFIG_SWIOTLB)
        pci_unmap_single(dev_handle, sg_dma_address(&sgl[i]), sg_dma_len(&sgl[i]), (int)dma_direction);
#endif
        if (!PageReserved(sgl[i].page))
            SetPageDirty(sgl[i].page);
        page_cache_release(sgl[i].page);
    }
    vfree(sgl);
#elif defined(LINUX_24)
#if defined(KIOBUF_WITH_SIZE)
    int nbhs = KIO_MAX_SECTORS;
#endif
    struct kiobuf *iobuf = (struct kiobuf *)dma_handle;
    if (iobuf)
    {
        unmap_kiobuf(iobuf);
#if defined(KIOBUF_WITH_SIZE)
        free_kiovec_sz(1, &iobuf, &nbhs);
#else
        free_kiovec(1, &iobuf);
#endif
    }
#else
    // not supported by older kernels
    return 0x2000000aL;
#endif
    return 0;
}

int LINUX_atomic_inc(os_interlocked_t *val)
{
#if defined(POWERPC) || defined(PPC64)
    return atomic_inc_return((atomic_t *)val);
#else
    atomic_t *v = (atomic_t *)val;      
    atomic_inc(v);
    return v->counter;
#endif
}

int LINUX_atomic_dec(os_interlocked_t *val)
{
#if defined(POWERPC) || defined(PPC64)
    return atomic_dec_return((atomic_t *)val);
#else
    atomic_t *v = (atomic_t *)val;
    atomic_dec(v);
    return v->counter;
#endif
}

int LINUX_atomic_add(os_interlocked_t *val, int i)
{
#if defined(POWERPC) || defined(PPC64)
    return atomic_add_return(i, (atomic_t *)val); 
#else
    atomic_t *v = (atomic_t *)val;
    atomic_add(i, v);
    return v->counter;
#endif
}

int LINUX_atomic_read(os_interlocked_t *val)
{
    return atomic_read((atomic_t *)val);
}

void LINUX_atomic_set(os_interlocked_t *val, int i)
{
    atomic_set((atomic_t *)val, i);
}

void LINUX_atomic_init(os_interlocked_t *val)
{
    atomic_set((atomic_t *)val, 0);
}

void LINUX_atomic_uninit(os_interlocked_t *val)
{
    val = val;
}

void LINUX_event_wait(struct semaphore **event)
{
    int rc;
    rc = down_interruptible(*event);
}

void LINUX_event_create(struct semaphore **event)
{
    *event = LINUX_create_mutex();
}

void LINUX_event_set(struct semaphore **event)
{
   up(*event);
}

void LINUX_event_destroy(struct semaphore **event)
{
    LINUX_free_mutex(*event);
}

void LINUX_pci_set_master(void *dev_h)
{
    pci_set_master(dev_h);
}

int LINUX_pci_enable_device(void *dev_h)
{
#if defined(LINUX_24_26)
    return pci_enable_device(dev_h);
#endif
    return 0;
}

void LINUX_pci_disable_device(void *dev_h)
{
#if defined(LINUX_24_26)
    pci_disable_device(dev_h);
#endif
}

int LINUX_pci_request_regions(void *dev_h, char *modulename)
{
#if defined(LINUX_24_26)
    return pci_request_regions(dev_h, modulename);
#endif
    return 0;
}

void LINUX_pci_release_regions(void *dev_h)
{
#if defined(LINUX_24_26)
    pci_release_regions(dev_h);
#endif
}

unsigned char LINUX_inb(unsigned short port)
{
    return inb(port);
}

unsigned short LINUX_inw(unsigned short port)
{
    return inw(port);
}

unsigned int LINUX_inl(unsigned short port)
{
    return inl(port);
}

void LINUX_outb(unsigned char value, unsigned short port)
{
    outb(value, port);
}

void LINUX_outw(unsigned short value, unsigned short port)
{
    outw(value, port);
}

void LINUX_outl(unsigned int value, unsigned short port)
{
    outl(value, port);
}

void LINUX_insb(unsigned short port, void *addr, unsigned long count)
{
    insb(port, addr, count);
}
void LINUX_insw(unsigned short port, void *addr, unsigned long count)
{
    insw(port, addr, count);
}

void LINUX_insl(unsigned short port, void *addr, unsigned long count)
{
    insl(port, addr, count);
}

void LINUX_outsb(unsigned short port, void *addr, unsigned long count)
{
   outsb(port, addr, count);
}

void LINUX_outsw(unsigned short port, void *addr, unsigned long count)
{
   outsw(port, addr, count);
}

void LINUX_outsl(unsigned short port, void *addr, unsigned long count)
{
   outsl(port, addr, count);
}

char *LINUX_strcpy(char *dest,const char *src)
{
    return strcpy(dest, src);
}

char *LINUX_strcat(char *dest,const char *src)
{
    return strcat(dest, src);
}

int LINUX_strcmp(const char *cs,const char *ct)
{
    return strcmp(cs, ct);
}

int LINUX_strncmp(const char *cs,const char *ct, unsigned long count)
{
   return strncmp(cs, ct, count);
}

void *LINUX_memset(void *adrr ,int s, unsigned long count)
{
    return memset(adrr, s, count);
}

void *LINUX_memcpy(void *to, const void *from, unsigned long n)
{
   return memcpy(to, from, n);
}

int LINUX_memcmp(void *to, const void *from, unsigned long n)
{
   return memcmp(to, from, n);
}
unsigned long LINUX_strlen(const char *s)
{
    return strlen(s);
}
 
char *LINUX_strncpy(char *dest, const char *src, unsigned long count)
{
    return strncpy(dest, src, count);
}

#if defined(LINUX_24_26)
#define ITEM_MEMORY 2
#define ITEM_IO 3

int LINUX_pci_resource_type(void *dev_h, int i)
{
    struct pci_dev *dev = (struct pci_dev *)dev_h;
    int flags = pci_resource_flags (dev, i);
    if (flags & IORESOURCE_IO)
        return ITEM_IO;
    if (flags & IORESOURCE_MEM)
        return ITEM_MEMORY;
    return -1;
}

unsigned long LINUX_pci_resource_start(void *dev_h, int i)
{
    struct pci_dev *dev = (struct pci_dev *)dev_h;
    return pci_resource_start (dev, i);
}

unsigned long LINUX_pci_resource_len(void *dev_h, int i)
{
    struct pci_dev *dev = (struct pci_dev *)dev_h;
    return pci_resource_len (dev, i);
}
#else

int LINUX_pci_resource_type(void *dev_h, int i)
{
    return 0;
}

unsigned long LINUX_pci_resource_start(void *dev_h, int i)
{
    return 0;
}

unsigned long LINUX_pci_resource_len(void *dev_h, int i)
{
    return 0;
}
#endif

void *LINUX_pci_find_slot(unsigned int bus, unsigned int devfn)
{
    return pci_find_slot(bus, devfn);
}

void *LINUX_pci_bus(void *dev_h)
{
    return ((struct pci_dev *)dev_h)->bus;
}

void *LINUX_pci_bus_subordinate(void *dev_h)
{
    return ((struct pci_dev *)dev_h)->subordinate;
}

#if defined(LINUX_26) && defined(CONFIG_HOTPLUG)
void *LINUX_pci_find_bus(int domain, int busnr)
{
    return pci_find_bus(domain, busnr);
}

int LINUX_pci_scan_slot(void *bus_h, int devfn)
{
    return pci_scan_slot((struct pci_bus *)bus_h, devfn); 
}

void LINUX_pci_bus_add_devices(void *bus_h)
{
    pci_bus_add_devices((struct pci_bus *)bus_h);
}

void LINUX_pci_bus_size_bridges(void *bus_h)
{
    pci_bus_size_bridges((struct pci_bus *)bus_h);
}

void LINUX_pci_bus_assign_resources(void *bus_h)
{
    pci_bus_assign_resources((struct pci_bus *)bus_h);
}

void LINUX_pci_remove_bus_device(void *dev_h)
{
    pci_remove_bus_device((struct pci_dev *)dev_h);
}

#else

void *LINUX_pci_find_bus(int domain, int busnr)
{
    return 0;
}

int LINUX_pci_scan_slot(void *bus_h, int devfn)
{
    return 0;
}

void LINUX_pci_bus_add_devices(void *bus_h)
{}

void LINUX_pci_bus_size_bridges(void *bus_h)
{}

void LINUX_pci_bus_assign_resources(void *bus_h)
{}

void LINUX_pci_remove_bus_device(void *dev_h)
{}
#endif

unsigned long LINUX_get_page_size(void) 
{
    return PAGE_SIZE;
}

unsigned long LINUX_get_page_shift(void) 
{
    return PAGE_SHIFT;
}

/*
 * The readX() and writeX() interface automatically swap bytes
 * on big endian hosts
 */
unsigned char LINUX_read8(volatile void *addr)
{
    return readb((void *)addr);
}

unsigned short LINUX_read16(volatile void *addr)
{
    return readw((void *)addr);
}

unsigned int LINUX_read32(volatile void *addr)
{
    return readl((void *)addr);
}

_u64 LINUX_read64(volatile void *addr)
{
#ifdef readq
    return readq((void *)addr);
#else /* readq is not defined for all platforms */
    return le64_to_cpu(*(volatile _u64 *)(addr));
#endif
}

void LINUX_write8(unsigned char val, volatile void *addr)
{
    writeb(val, addr);
}

void LINUX_write16(unsigned short val, volatile void *addr)
{
    writew(val, addr);
}

void LINUX_write32(unsigned int val, volatile void *addr)
{
    writel(val, addr);
}

void LINUX_write64(_u64 val, volatile void *addr)
{
#ifdef writeq
    writeq(val, addr);
#else /* writeq is not defined for all platforms */
    *(volatile _u64 *)(addr) = cpu_to_le64(val);
#endif
}

