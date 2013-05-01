#ifndef _P2PMESSAGE_H_
#define _P2PMESSAGE_H_

#include "stddef.h"
#include "stdint.h"

#include <lib6lowpan/6lowpan.h>

#define MAX_PEER_CONNECTIONS 16

#define MAX_TORRENT_SIZE 8192
#define PIECE_SIZE 256

#define MAX_P2P_MESG_SIZE 512

#include "hash.h"
#include "bitvector.h"


typedef struct {
    uint16_t port;
    uint8_t address[16];
} addr_t;

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

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  hash_t sum; // Piece Id (hash)
  hash_t tid; // Torrent Id (hash)
  uint16_t index; // index of piece in file
  uint16_t count; // piece size
  uint8_t* payload; // piece data
  
} piece_t;

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  addr_t tracker; // tracker address

  uint16_t piecesCount; // number of pieces in file
  uint16_t pieceSize; // piece size in bytes
  hash_t* pieceSums;  // array of piece Id's (hash)

} torrent_t;

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


typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  hash_t peerId;
  addr_t address;

  bitvector_t interests;
  bitvector_t completed;

} peer_t;

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  addr_t addr;

  torrent_t torrent;

  uint16_t swarmSize;

} tracker_t;
#endif
