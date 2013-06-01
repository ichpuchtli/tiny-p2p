#include <stdint.h>

#include "torrent.h"
#include "addr.h"
#include "tracker.h"
#include "peer.h"
#include "misc.h"
#include "bitvector.h"
#include "piece.h"

interface P2PMessage {


  // Tracker Events
  event void recvScrapeRequest(addr_t* from, torrent_t* torrent);

  event void recvAnnounceRequest(addr_t* from);

  // Tracker Commands   
  command void sendScrapeResponse(addr_t* to, torrent_t* torrent); 

  command void sendAnnounceResponse(addr_t* to, addr_t* peer); 

  // Client Events

  event void recvScrapeResponse(torrent_t* torrent);

  event void recvAnnounceResponse(peer_t* peer);

  event void recvHandShake(hash_t peerId, peer_t* peerInfo);
  
  event void recvInterest(hash_t peerId, bitvector_t* pieces);

  event void recvPiece(hash_t peerId, piece_t* piece);


  // Client Commands

  // Generic Message Command
  command void sendMessage(addr_t* to, p2p_mesg_t type, uint8_t* payload, uint16_t count); 

  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  command void handshake(addr_t* to, peer_t* peerInfo);

  // Send empty meta to receive information about a possible torrent
  // Send a meta packet to create a torrent and store it on the tracker
  command void scrape(addr_t* to, torrent_t* meta);

  // Acknowledge your presents in the p2p network and ask for another peer
  command void announce(addr_t* to);

  // Send a piece to an address
  command void sendPiece(addr_t* to, piece_t* piece);

  // Send a bitvector of the pieces your peer is interested in downloading
  command void sendInterest(addr_t* to, bitvector_t* pieces);

}
