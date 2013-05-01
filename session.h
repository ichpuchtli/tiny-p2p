#ifndef __SESSION_H__
#define __SESSION_H__

#include <stdint.h>
#include "misc.h"
#include "torrent.h"
#include "bitvector.h"



typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  uint16_t uploaded; // #pieces sent 
  uint16_t downloaded; // #pieces downloaded
  uint16_t left; // #pieces left to download downloaded

  uint16_t snubbed; // #peer's snubbed
  uint16_t handshakes; // #peer's handshaked
  uint16_t interests; // #interests sent

  uint16_t connections; // #opened connections
  uint16_t swarmSize; // #total number of peers known to this peer

  uint16_t announces; // #announces made
  uint16_t scrapes; // #scrapes made

  bitvector_t progress; // bitvector of pieces collected

  torrent_t torrent; // the torrent we are currently downloadnig

  status_t status; // the status of this peer

} session_t;



#endif

