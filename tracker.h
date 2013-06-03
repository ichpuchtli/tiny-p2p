#ifndef __TRACKER_H__
#define __TRACKER_H__

#include <stdint.h>

#include "misc.h"
#include "addr.h"
#include "torrent.h"

#define TRACKER_PORT     1300
#define TRACKER_ADDR_STR "fec0::3"

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  addr_t addr;
  hash_t id;

  torrent_t torrent;

  uint16_t swarmSize;

} tracker_t;

#endif
