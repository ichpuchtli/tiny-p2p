#include "bitvector.h"

#include <string.h>

static unsigned int getIndex(unsigned int bitnum) {
  return bitnum / ELEMENT_SIZE;
}

static unsigned int getMask(unsigned int bitnum) {
  return 1 << (bitnum % ELEMENT_SIZE);
}

void vBitVectorClearAll(bitvector_t* vector) {
  memset((void*) vector, 0, sizeof(bitvector_t));
}

void vBitVectorSetAll(bitvector_t* vector) {
  memset((void*) vector, 255, sizeof(bitvector_t));
}

char cBitVectorGet(bitvector_t* vector, unsigned int bitnum) {
  return (vector->m_bits[getIndex(bitnum)] & getMask(bitnum)) ? 1 : 0;
}

void vBitVectorSet(bitvector_t* vector, unsigned int bitnum) {
  vector->m_bits[getIndex(bitnum)] |= getMask(bitnum);
}

void vBitVectorClear(bitvector_t* vector, unsigned int bitnum) {
  vector->m_bits[getIndex(bitnum)] &= ~getMask(bitnum);
}

void vBitVectorToggle(bitvector_t* vector, unsigned int bitnum) {
  vector->m_bits[getIndex(bitnum)] ^= getMask(bitnum);
}

void vBitVectorOREQ(bitvector_t* dest, bitvector_t* vector){

  unsigned int index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] |= vector->m_bits[index];

}

void vBitVectorANDEQ(bitvector_t* dest, bitvector_t* vector){

  unsigned int index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] &= vector->m_bits[index];
}

void vBitVectorXOREQ(bitvector_t* dest, bitvector_t* vector){

  unsigned int index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] ^= vector->m_bits[index];
}

unsigned int ulBitVectorSize(void) {
  return MAX_TORRENT_SIZE;
}

