#include <stdint.h>

#include "torrent.h"
#include "addr.h"
#include "tracker.h"
#include "peer.h"
#include "misc.h"
#include "bitvector.h"
#include "piece.h"

interface P2PMessage {

  //////////////////////////////////////////////////////////////////////////////
  // Commands
  
  // Generic Message Command
  async command void sendMessage(addr_t* peer, p2p_mesg_t type, uint8_t* payload, uint16_t count); 

  async command void ping(addr_t* peer);

  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  async command void handshake(addr_t* peer);

  // Send empty meta to receive information about a possible torrent
  // Send a meta packet to create a torrent and store it on the tracker
  async command void scrape(torrent_t* meta);

  // Acknowledge your presents in the p2p network and ask for another peer
  async command void announce(void);

  // Send a piece to an address
  async command void sendPiece(addr_t* peer, piece_t* piece);

  // Send a bitvector of the pieces your peer is interested in downloading
  async command void sendInterest(addr_t* peer, bitvector_t* pieces);

  //////////////////////////////////////////////////////////////////////////////
  // Events
  
  event void recvScrapeResponse(tracker_t* trackerStatus);

  event void recvAnnounceResponse(peer_t* peer);

  event void recvHandShake(addr_t* addr, peer_t* peerInfo);
  
  event void recvInterest(peer_t* peer, bitvector_t* pieces);

  event void recvPiece(peer_t* peer, piece_t* piece);

}
