#include <stdint.h>

#include <lib6lowpan/6lowpan.h>
#include "P2PMessage.h"

#include "hash.h"
#include "bitvector.h"
#include "torrent.h"
#include "tracker.h"
#include "peer.h"
#include "piece.h"
#include "addr.h"

module P2PMessageP {

  provides interface P2PMessage;
  provides interface Init;

  uses interface UDP as MesgSock;
  uses interface Debug;

  uses interface SplitControl as SocketControl;

} implementation {


  command error_t Init.init(){

    call SocketControl.start();
    call MesgSock.bind(P2PMESSAGE_PORT);
    
    return SUCCESS;
  }

  event void MesgSock.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {

    p2p_header_t* mesg = (p2p_header_t*) data;

    hash_t peerId = hash((uint8_t*) from, sizeof(struct sockaddr_in6));

    /*
    call Debug.sendString("Message: Received [");
    call Debug.sendNum((int16_t) peerId, 10);
    call Debug.sendString(", ");
    call Debug.sendNum(len, 10);
    call Debug.sendString(", ");
    call Debug.sendNum(mesg->type, 10);
    call Debug.sendByte(']');
    call Debug.sendByte('\n');
    */

    switch(mesg->type){

      // Tracker Events
      case MESSAGE_SCRAPE:
        // Scrape Request from a client to a tracker
        signal P2PMessage.recvScrapeRequest((addr_t*) from, (torrent_t*) data);
        break;

      case MESSAGE_ANNOUNCE:
        // Scrape Request from a client to a tracker
        signal P2PMessage.recvAnnounceRequest((addr_t*) from);
        break;

      // Client Events
      case MESSAGE_SCRAPE_RESPONSE:
        // Scrape Response from tracker
        signal P2PMessage.recvScrapeResponse((torrent_t*) data);
        break;

      case MESSAGE_ANNOUNCE_RESPONSE:
        // Announce response from tracker
        signal P2PMessage.recvAnnounceResponse((peer_t*) data);
        break;

      case MESSAGE_HANDSHAKE:
        // TODO perhaps update peer table here
        signal P2PMessage.recvHandShake(peerId, (peer_t*) data);
        break;

      case MESSAGE_INTEREST:
        signal P2PMessage.recvInterest(peerId, (bitvector_t*) data);
        break;

      case MESSAGE_PIECE:
        signal P2PMessage.recvPiece(peerId, (piece_t*) data);
        break;

      default:
        call Debug.sendString("Message: Error unknown message type\r\n");
        break;

    }

  }

  command void P2PMessage.sendMessage(addr_t* to, p2p_mesg_t type, uint8_t* payload, uint16_t count){

    p2p_header_t null_header;

    hash_t peerId = hash((uint8_t*) to, sizeof(struct sockaddr_in6));

    //TODO not sure if this is safe, depends if sendto is sync or at least copies the mesg
    p2p_header_t* mesg = &null_header;

    if(payload){
      mesg = (p2p_header_t*) payload;
    }

    mesg->type = type;
    mesg->len = count;

    /*
    call Debug.sendString("Message: Sent [");
    call Debug.sendNum((int16_t) peerId, 10);
    call Debug.sendString(", ");
    call Debug.sendNum(count, 10);
    call Debug.sendString(", ");
    call Debug.sendNum(mesg->type, 10);
    call Debug.sendByte(']');
    call Debug.sendByte('\n');

    */
    call MesgSock.sendto((struct sockaddr_in6*) to, (void*) mesg, mesg->len);

  }


  // Tracker Commands
  command void P2PMessage.sendScrapeResponse(addr_t* to, torrent_t* torrent){
    call P2PMessage.sendMessage(to, MESSAGE_SCRAPE_RESPONSE, (uint8_t*) torrent, sizeof(torrent_t));
  }

  command void P2PMessage.sendAnnounceResponse(addr_t* to, addr_t* peer){
    call P2PMessage.sendMessage(to, MESSAGE_ANNOUNCE_RESPONSE, (uint8_t*) peer, sizeof(addr_t));
  } 

  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  // Who you are (PeerID) , what your after(torrent_t{bitvector,sha1}), what port you listen on(port_t), etc..
  command void P2PMessage.handshake(addr_t* to, peer_t* peerInfo){
    call P2PMessage.sendMessage(to, MESSAGE_HANDSHAKE, (uint8_t*) peerInfo, sizeof(peer_t));
  }

  // Ask the tracker for information about a torrent, tracker load, swarm status etc..
  // Empty torrent meta signals new torrent
  command void P2PMessage.scrape(addr_t* to, torrent_t* meta){
    call P2PMessage.sendMessage(to, MESSAGE_SCRAPE, (uint8_t*) meta, sizeof(torrent_t));
  }

  // Acknowledge your presents in the p2p network and ask for peers
  command void P2PMessage.announce(addr_t* to){
    call P2PMessage.sendMessage(to, MESSAGE_ANNOUNCE, (uint8_t*) 0, 0);
  }

  // Send a piece to an address
  command void P2PMessage.sendPiece(addr_t* to, piece_t* piece){
    call P2PMessage.sendMessage(to, MESSAGE_PIECE, (uint8_t*) piece, PIECE_SIZE);
  }

  // Request a peice from an address; not sure when or if this mechanism will be used
  // Use a zero len piece to signal peice request
  command void P2PMessage.sendInterest(addr_t* to, bitvector_t* pieces){
    call P2PMessage.sendMessage(to, MESSAGE_INTEREST, (uint8_t*) pieces, sizeof(bitvector_t));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  event void SocketControl.startDone(error_t e) { }
  event void SocketControl.stopDone(error_t e) { }

}
