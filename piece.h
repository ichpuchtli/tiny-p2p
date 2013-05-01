#ifndef __PIECE_H__
#define __PIECE_H__

#include <stdint.h>

#include "hash.h"
#include "misc.h"

#define PIECE_SIZE 32

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  hash_t sum; // Piece Id (hash)
  hash_t tid; // Torrent Id (hash)

  uint16_t index; // index of piece in file
  uint16_t count; // piece size
  uint8_t piece[PIECE_SIZE]; // piece data
  
} piece_t;


#endif
