#include <stdint.h>

#include <lib6lowpan/6lowpan.h>

#include "hash.h"
#include "bitvector.h"
#include "torrent.h"
#include "tracker.h"
#include "peer.h"
#include "piece.h"
#include "addr.h"

#define MAX_P2P_MESG_SIZE 512

module P2PMessageP {

  provides interface P2PMessage;
  provides interface Init;

  uses interface UDP as MesgSock;
  uses interface Debug;

  uses interface SplitControl as SocketControl;

  //uses interface StdControl as MesgCtrl;

  // TODO Litter Module with debug messages
  //uses interface ICMPPing;

} implementation {


  command error_t Init.init(){

    call SocketControl.start();
    call MesgSock.bind(23);
    
    return SUCCESS;

  }

  event void MesgSock.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {

    p2p_header_t* mesg = (p2p_header_t*) data;

    hash_t peerId = hash((uint8_t*) from, sizeof(addr_t));

    //peer_t* peer = pxPeerTableWalk(peerId);
    peer_t* peer;

    // TODO Check(len == mesg->len)

    switch(mesg->type){

      case MESSAGE_SCRAPE_RESPONSE:
        signal P2PMessage.recvScrapeResponse((tracker_t*) data);
        break;

      case MESSAGE_ANNOUNCE_RESPONSE:
        signal P2PMessage.recvAnnounceResponse((peer_t*) data);
        break;

      case MESSAGE_HANDSHAKE:
        // TODO perhaps update peer table here
        signal P2PMessage.recvHandShake((addr_t*) from, (peer_t*) data);
        break;

      case MESSAGE_INTEREST:
        signal P2PMessage.recvInterest(peer, (bitvector_t*) data);
        break;

      case MESSAGE_PIECE:
        signal P2PMessage.recvPiece(peer, (piece_t*) data);
        break;

      case MESSAGE_PIECE_ACK:
        // TODO maybe some internal handling here
        //signal P2PMessage.recvPieceAck(peer);
        break;

      case MESSAGE_INTEREST_ACK:
        // TODO maybe some internal handling here
        //signal P2PMessage.recvInterestAck(peer);
        break;

      case MESSAGE_HANDSHAKE_RESPONSE:
        // TODO perhaps update peer table here
        // TODO maybe some internal handling here
        //signal P2PMessage.recvHandshakeResponse(peer, (peer_t*) payload);
        break;

      default: break;
               // TODO unknown message event
        break;

    }


  }

/*
  event void ICMPPing.pingReply(struct in6_addr *source, struct icmp_stats *stats) {
    int len;
    len = inet_ntop6(source, reply_buf, MAX_REPLY_LEN);
    if (len > 0) {
      len += snprintf(reply_buf + len - 1, MAX_REPLY_LEN - len + 1, ping_fmt,
                      stats->seq, stats->ttl, stats->rtt);
      reply_buf[len] = '\0';
      call UDP.sendto(&session_endpoint, reply_buf, len);
    }
  }

  event void ICMPPing.pingDone(uint16_t ping_rcv, uint16_t ping_n) {
    int len;
    len = snprintf(reply_buf, MAX_REPLY_LEN, ping_summary, ping_n, ping_rcv);
    call UDP.sendto(&session_endpoint, reply_buf, len);
  }
*/

  async command void P2PMessage.sendMessage(addr_t* peer, p2p_mesg_t type, uint8_t* payload, uint16_t count){

    // TODO queue's for each packet type 
    p2p_header_t* mesg = (p2p_header_t*) payload;

    mesg->type = type;
    mesg->len = count;

    call MesgSock.sendto((struct sockaddr_in6*) peer, (void*) mesg, mesg->len);

  }

  // Similar to Ping just checks for a response; payload ignored 
  async command void P2PMessage.ping(addr_t* peer){

    //call ICMPPing.ping((addr_t*) peer, 1024, 10);
  }

  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  // Who you are (PeerID) , what your after(torrent_t{bitvector,sha1}), what port you listen on(port_t), etc..
  async command void P2PMessage.handshake(addr_t* peer){ }

  // Ask the tracker for information about a torrent, tracker load, swarm status etc..
  // Empty torrent meta signals new torrent
  async command void P2PMessage.scrape(torrent_t* meta){
    //call P2PMessage.sendMessage(TRACKER_ID, MESSAGE_SCRAPE, (uint8_t*) meta, META_SIZE);
  }

  // Acknowledge your presents in the p2p network and ask for peers
  async command void P2PMessage.announce(void){}

  // Send a piece to an address
  async command void P2PMessage.sendPiece(addr_t* peer, piece_t* piece){
    call P2PMessage.sendMessage(peer, MESSAGE_PIECE, (uint8_t*) piece, PIECE_SIZE);
  }

  // Request a peice from an address; not sure when or if this mechanism will be used
  // Use a zero len piece to signal peice request
  async command void P2PMessage.sendInterest(addr_t* peer, bitvector_t* pieces){
    //call P2PMessage.sendMessage(peerId, MESSAGE_INTEREST, (uint8_t*) pieceId, ulHashSize(pieceId));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  event void SocketControl.startDone(error_t e) { }
  event void SocketControl.stopDone(error_t e) { }

}
