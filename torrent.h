#ifndef __TORRENT_H__
#define __TORRENT_H__

#include <stdint.h>
#include "misc.h"
#include "hash.h"
#include "addr.h"

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  addr_t source;  // source peer

  uint16_t pieces; // number of pieces in file
  uint16_t pieceSize; // piece size in bytes
  //hash_t* pieceSums;  // array of piece Id's (hash)

} torrent_t;

#endif
