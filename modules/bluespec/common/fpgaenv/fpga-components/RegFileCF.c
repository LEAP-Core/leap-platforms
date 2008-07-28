#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    uint32_t addr_mask;
    uint32_t data_words;
    uint32_t depth;
    uint32_t *buf;
} regfile_cf_t;

const int debug = 0;
static FILE *file = NULL;

void regfile_cf_upd (uint64_t handle, uint32_t *addr_p, uint32_t *data_p)
{
    regfile_cf_t *ptr = (regfile_cf_t *) (uintptr_t) handle;
    uint32_t addr = ptr->addr_mask & *addr_p;
    memcpy(ptr->buf + (addr * ptr->data_words), data_p, ptr->data_words * 4);
    if (debug)
        fprintf(file, "W %0lx %0x %0x\n", handle, addr, *data_p/*hack*/);
}

void regfile_cf_sub (uint32_t *data_p, uint64_t handle, uint32_t *addr_p)
{
    regfile_cf_t *ptr = (regfile_cf_t *) (uintptr_t) handle;
    uint32_t addr = ptr->addr_mask & *addr_p;
    memcpy(data_p, ptr->buf + (addr * ptr->data_words), ptr->data_words * 4);
    if (debug)
        fprintf(file, "R %0lx %0x %0x\n", handle, addr, *data_p/*hack*/);
}

uint64_t regfile_cf_init (uint32_t addr_sz, uint32_t data_sz, uint32_t depth)
{
    regfile_cf_t *ptr = malloc(sizeof(regfile_cf_t));
    if (addr_sz > 31) {
        printf("Error: RegFileCF: can only support index_t upto 31 bits");
        exit(1);
    }
    ptr->addr_mask = (1 << addr_sz) - 1;
    ptr->data_words = (data_sz + 31) / 32;
    ptr->depth = depth;
    ptr->buf = malloc(depth * ptr->data_words * 4);
    memset(ptr->buf, 0xaa, depth * ptr->data_words * 4);
    if (debug)
        file = fopen("RegFileCF.log", "w");
    return (uint64_t) (uintptr_t) ptr;
}
