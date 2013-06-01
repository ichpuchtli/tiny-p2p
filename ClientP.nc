#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/6lowpan.h>
#include <lib6lowpan/ip.h>

#define MAX_TORRENT_SIZE 8192
#define DEFAULT_PKT_SIZE 256

#include "tracker.h" //TRACKER_PORT, TRACKER_ADDR_STR, tracker_t
#include "peer.h" // pxPeerTable[], pxPeerTableWalk(peer_t), peer_t
#include "session.h"
#include "P2PMessage.h" // P2PMESSAGE_PORT
#include "bitvector.h"

#define xstr(a) str(a)
#define str(a) #a

enum {
  DAEMON_IDLE     = 0,
  DAEMON_SCRAPE   = 1,
  DAEMON_ANNOUNCE = 3,
  DAEMON_LEECH    = 4,
  DAEMON_SEED     = 5
};


module ClientP {

  uses interface Boot;
  uses interface Timer<TMilli> as Timer;

  uses interface Leds;

  // Radio Comm
  //uses interface SplitControl as RadioControl;

  // p2p message protocol
  uses interface P2PMessage as Message;

  // Serial Comm
  uses interface Debug;

  //uses interface FileSystem as Files;
  
  // Poke, sync ping service 
  //uses interface Poke;

} implementation {

  tracker_t xTracker;

  // Boot
  event void Boot.booted() {


    xTracker.addr.port = htons(TRACKER_PORT);
    inet_pton6(TRACKER_ADDR_STR, (struct in6_addr*) &xTracker.addr.addr);

    xTracker.id = hash((uint8_t*) &xTracker.addr ,sizeof(addr_t));

    call Debug.sendString("Tracker Addr: fec0::1\r\n");

    inet_pton6(TRACKER_ADDR_STR, (struct in6_addr*) &xTracker.torrent.tracker.addr);
    xTracker.torrent.tracker.port = htons(TRACKER_PORT);

    xTracker.torrent.piecesCount = 0;
    xTracker.torrent.pieceSize = 0;

    call Debug.sendString("Booted!\r\n");

  }

  // Tracker Events
  event void Message.recvScrapeRequest(addr_t* from, torrent_t* torrent){

    call Debug.sendString("recvScrapeRequest: Scrape Requested!\r\n");

    call Message.sendScrapeResponse(from, &xTracker.torrent);
  }

  event void Message.recvAnnounceRequest(addr_t* from){}

  // Client Events
  event void Message.recvScrapeResponse(torrent_t* torrent){}

  event void Message.recvAnnounceResponse(peer_t* peer){}

  event void Message.recvHandShake(hash_t peerId, peer_t* peerInfo){}
  
  event void Message.recvInterest(hash_t peerId, bitvector_t* pieces){ }

  event void Message.recvPiece(hash_t peerId, piece_t* piece){ }

  event void Timer.fired() {}

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  //event void RadioControl.startDone(error_t e) { }
  //event void RadioControl.stopDone(error_t e) { }

}

