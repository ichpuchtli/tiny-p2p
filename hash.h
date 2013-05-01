#ifndef _HASH_H_
#define _HASH_H_

#include <stdint.h>

#include "../chips/atm128/crc.h"

typedef uint16_t hash_t;

hash_t hash(uint8_t* data, uint16_t count){

    hash_t sum = 0;

    while(count--) sum = crcByte(sum, data[count]);

    return sum;
}

#endif
