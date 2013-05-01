#ifndef __BITVECTOR_H__
#define __BITVECTOR_H__

#include <stdint.h>

#define MAX_TORRENT_SIZE 8192

typedef uint8_t int_type;

#define ELEMENT_SIZE (8*sizeof(int_type))
#define ARRAY_SIZE   ((MAX_TORRENT_SIZE + ELEMENT_SIZE-1) / ELEMENT_SIZE)

typedef struct {

  int_type m_bits[ ARRAY_SIZE ];

} bitvector_t;

void vBitVectorSetAll(bitvector_t* vector);
void vBitVectorClearAll(bitvector_t* vector);

uint8_t cBitVectorGet(bitvector_t* vector, uint16_t bitnum);

void vBitVectorSet(bitvector_t* vector, uint16_t bitnum);
void vBitVectorClear(bitvector_t* vector, uint16_t bitnum);
void vBitVectorToggle(bitvector_t* vector, uint16_t bitnum);

void vBitVectorOREQ(bitvector_t* dest, bitvector_t* vector);
void vBitVectorANDEQ(bitvector_t* dest, bitvector_t* vector);
void vBitVectorXOREQ(bitvector_t* dest, bitvector_t* vector);

uint16_t ulBitVectorSize(void);

#endif
