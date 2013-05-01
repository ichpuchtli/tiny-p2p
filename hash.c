#include "crc.h"
#include "hash.h"

hash_t hash(uint8_t* data, uint16_t count){

    hash_t sum = 0;

    while(count--) sum = crcByte(sum, data[count]);

    return sum;
}
