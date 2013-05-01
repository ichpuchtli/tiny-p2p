#ifndef __MISC_H__
#define __MISC_H__

#include <stdint.h>

typedef enum {

  LEECHING,
  SEEDING,
  IDLE,
  ERROR,

} status_t;

typedef enum {

  MESSAGE_PIECE,
  MESSAGE_PIECE_ACK,
  MESSAGE_INTEREST,
  MESSAGE_INTEREST_ACK,
  MESSAGE_SCRAPE,
  MESSAGE_SCRAPE_RESPONSE,
  MESSAGE_ANNOUNCE,
  MESSAGE_ANNOUNCE_RESPONSE,
  MESSAGE_HANDSHAKE,
  MESSAGE_HANDSHAKE_RESPONSE,

} p2p_mesg_t;

typedef struct {

  p2p_mesg_t type;
  uint16_t len;

} p2p_header_t;

#endif
