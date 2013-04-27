#include "stddef.h"
#include "stdint.h"

typedef enum {

  LEECHING,
  SEEDING,
  IDLE,
  ERROR,

} status_t;

typedef struct {

  uint8_t sum[16];

} hash_t;

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

} message_t;

typedef uint16_t port_t;

typedef struct {

  uint8_t addr[16];
  port_t port;

} addr_t;

typedef struct {

  hast_t sum; // Piece Id (hash)
  hash_t tid; // Torrent Id (hash)
  uint16_t index; // index of piece in file
  uint16_t count; // piece size
  uint8_t* payload; // piece data
  
} piece_t;

typedef struct {

  addr_t tracker; // tracker address

  uint16_t piecesCount; // number of pieces in file
  uint16_t peiceSize; // piece size in bytes
  hash_t* pieceSums;  // array of piece Id's (hash)

} torrent_t;

typedef struct {

  uint16_t uploaded; // #pieces sent 
  uint16_t downloaded; // #pieces downloaded

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
  message_t type;
  size_t len;
  uint8_t payload[1];
} message_packet_t;
