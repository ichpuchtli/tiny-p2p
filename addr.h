#ifndef __ADDR_H__
#define __ADDR_H__

#include <stdint.h>

typedef struct {

    uint16_t port;
    uint8_t addr[16];

} addr_t;

#endif
