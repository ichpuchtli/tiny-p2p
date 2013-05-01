#include "bitvector.h"

static uint16_t getIndex(uint16_t bitnum) {
  return bitnum / ELEMENT_SIZE;
}

static uint16_t getMask(uint16_t bitnum) {
  return 1 << (bitnum % ELEMENT_SIZE);
}

void vBitVectorClearAll(bitvector_t* vector) {
  memset((void*) vector, 0, sizeof(bitvector_t));
}

void vBitVectorSetAll(bitvector_t* vector) {
  memset((void*) vector, 255, sizeof(bitvector_t));
}

bool cBitVectorGet(bitvector_t* vector, uint16_t bitnum) {
  return (vector->m_bits[getIndex(bitnum)] & getMask(bitnum)) ? 1 : 0;
}

void vBitVectorSet(bitvector_t* vector, uint16_t bitnum) {
  vector->m_bits[getIndex(bitnum)] |= getMask(bitnum);
}

void vBitVectorClear(bitvector_t* vector, uint16_t bitnum) {
  vector->m_bits[getIndex(bitnum)] &= ~getMask(bitnum);
}

void vBitVectorToggle(bitvector_t* vector, uint16_t bitnum) {
  vector->m_bits[getIndex(bitnum)] ^= getMask(bitnum);
}

void vBitVectorOREQ(bitvector_t* dest, bitvector_t* vector){

  uint16_t index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] |= vector->m_bits[index];

}

void vBitVectorANDEQ(bitvector_t* dest, bitvector_t* vector){

  uint16_t index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] &= vector->m_bits[index];
}

void vBitVectorXOREQ(bitvector_t* dest, bitvector_t* vector){

  uint16_t index = ARRAY_SIZE;

  while(index--)
      dest->m_bits[index] ^= vector->m_bits[index];
}

uint16_t ulBitVectorSize(void) {
  return MAX_TORRENT_SIZE;
}

