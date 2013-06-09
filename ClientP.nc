#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

#define MAX_TORRENT_SIZE 1024
#define DEFAULT_PKT_SIZE 256

#include "tracker.h" //TRACKER_PORT, TRACKER_ADDR_STR, tracker_t
#include "peer.h" // pxPeerTable[], pxPeerTableWalk(peer_t), peer_t
#include "session.h"
#include "P2PMessage.h" // P2PMESSAGE_PORT
#include "bitvector.h"

#define IS_CLIENT (TOS_NODE_ID == 3)

#define ENABLE_THREAD(T) do { g_usEnableDaemon |= (1 << (T)); } while(0)
#define DISABLE_THREAD(T) do { g_usEnableDaemon &= ~(1 << (T)); } while(0)

#define THREAD_ENABLED(T) (g_usEnableDaemon & (1 << (T)))

#define MAIN_LOOP_INTERVAL 100 /* milliseconds */

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
  uses interface Timer<TMilli>;

  uses interface Leds;

  // Radio Comm
  //uses interface SplitControl as RadioControl;

  // Serial Comm
  uses interface Debug;

  // p2p message protocol
  uses interface P2PMessage as Message;


} implementation {

  const uint16_t sinetable[256] = {2048, 1998, 1948, 1897, 1847, 1797,
    1747, 1698, 1648, 1599, 1550, 1502, 1453, 1406, 1358, 1311, 1264, 1218,
    1172, 1127, 1083, 1039, 995, 952, 910, 869, 828, 788, 749, 710, 673, 636,
    600, 565, 531, 497, 465, 433, 403, 374, 345, 318, 291, 266, 242, 219, 197,
    176, 156, 137, 120, 103, 88, 74, 61, 50, 39, 30, 22, 15, 10, 6, 2, 1, 0,
    1, 2, 6, 10, 15, 22, 30, 39, 50, 61, 74, 88, 103, 120, 137, 156, 176, 197,
    219, 242, 266, 291, 318, 345, 374, 403, 433, 465, 497, 531, 565, 600, 636,
    673, 710, 749, 788, 828, 869, 910, 952, 995, 1039, 1083, 1127, 1172, 1218,
    1264, 1311, 1358, 1406, 1453, 1502, 1550, 1599, 1648, 1698, 1747, 1797, 1847,
    1897, 1948, 1998, 2048, 2098, 2148, 2199, 2249, 2299, 2349, 2398, 2448, 2497,
    2546, 2594, 2643, 2690, 2738, 2785, 2832, 2878, 2924, 2969, 3013, 3057, 3101,
    3144, 3186, 3227, 3268, 3308, 3347, 3386, 3423, 3460, 3496, 3531, 3565,
    3599, 3631, 3663, 3693, 3722, 3751, 3778, 3805, 3830, 3854, 3877, 3899,
    3920, 3940, 3959, 3976, 3993, 4008, 4022, 4035, 4046, 4057, 4066, 4074,
    4081, 4086, 4090, 4094, 4095, 4095, 4095, 4094, 4090, 4086, 4081, 4074,
    4066, 4057, 4046, 4035, 4022, 4008, 3993, 3976, 3959, 3940, 3920, 3899,
    3877, 3854, 3830, 3805, 3778, 3751, 3722, 3693, 3663, 3631, 3599, 3565,
    3531, 3496, 3460, 3423, 3386, 3347, 3308, 3268, 3227, 3186, 3144, 3101,
    3057, 3013, 2969, 2924, 2878, 2832, 2785, 2738, 2690, 2643, 2594, 2546,
    2497, 2448, 2398, 2349, 2299, 2249, 2199, 2148, 2098};

  uint8_t* sensorData = (uint8_t*) sinetable;

  uint8_t fileBuffer[1024] = {0};

  piece_t pieceBuffer;

  volatile uint16_t g_usEnableDaemon;

  volatile uint8_t g_ucDaemonPriority[5];

  peer_t xThisPeer;
  tracker_t xTracker;
  torrent_t xTorrent;

  peer_t xPeer1;

  // Boot
  event void Boot.booted() {

    struct sockaddr_in6* saddr6 = (struct sockaddr_in6*) &xThisPeer.addr;

    call Debug.sendString("\n============== Boot Sequence ===========\r\n");

    // Initialize Peer Structure
    xThisPeer.addr.port = htons(P2PMESSAGE_PORT);
    inet_pton6("fec0::2", (struct in6_addr*) &xThisPeer.addr.addr);

    saddr6->sin6_addr.s6_addr[15] = TOS_NODE_ID; //NOTE 0-255 possible TOS_NODE_ID's

    xThisPeer.peerId = hash((uint8_t*) &xThisPeer.addr, sizeof(addr_t));

    //vBitVectorSetAll(&xThisPeer.interests);
    //vBitVectorClearAll(&xThisPeer.completed);

    call Debug.sendString("  Peer Addr: fec0::");
    call Debug.sendNum(TOS_NODE_ID,10);
    call Debug.sendByte('\n');
    call Debug.sendString("  Peer Port: " xstr(P2PMESSAGE_PORT));
    call Debug.sendByte('\n');
    call Debug.sendString("  Peer ID: ");
    call Debug.sendNum(xThisPeer.peerId, 10);
    call Debug.sendCRLF();

    call Debug.sendString("-----------------\r\n");

    xTracker.addr.port = htons(TRACKER_PORT);
    inet_pton6(TRACKER_ADDR_STR, (struct in6_addr*) &xTracker.addr.addr);
    xTracker.id = hash((uint8_t*) &xTracker.addr ,sizeof(addr_t));

    call Debug.sendString("  Tracker Addr: " TRACKER_ADDR_STR);
    call Debug.sendByte('\n');
    call Debug.sendString("  Tracker Port: " xstr(TRACKER_PORT));
    call Debug.sendByte('\n');
    call Debug.sendString("  Tracker ID: ");
    call Debug.sendNum(xTracker.id, 10);
    call Debug.sendCRLF();

    // Continually ping the tracker until we got a response. 
    //while(call Poke.poke(&xTracker.addr.addr, 2048) == 2048)
      //call Debug.sendByte('.');

    memset((void*) &xPeer1, '\0', sizeof(peer_t));
    memset((void*) &xTorrent, '\0', sizeof(torrent_t));

    xTorrent.pieceSize  = 64;
    xTorrent.pieces = 16;

    memcpy((void*) &xTorrent.source, (void*) &xThisPeer.addr, sizeof(addr_t));

    //vBitVectorSetAll(&xPeer1.interests);
    //vBitVectorClearAll(&xPeer1.completed);

    g_ucDaemonPriority[DAEMON_IDLE]     = 10;
    g_ucDaemonPriority[DAEMON_SCRAPE]   = 5;
    g_ucDaemonPriority[DAEMON_ANNOUNCE] = 5;
    g_ucDaemonPriority[DAEMON_LEECH]    = 5;
    g_ucDaemonPriority[DAEMON_SEED]     = 5;


    ENABLE_THREAD(DAEMON_SCRAPE);

    call Timer.startOneShot(2024); // Start main task chain
    call Debug.sendString("============== Main Loop ===============\r\n");

    call Debug.sendString("\nScraping");
  }

  void idle_worker(void* param){
  
    call Debug.sendString("idle\n");
  }
  
  void scrape_worker(void* param){

    call Debug.sendByte('.');

    if(IS_CLIENT){
      xTorrent.pieces = 0;
    }

    call Message.scrape(&xTracker.addr,&xTorrent);

  }

  void announce_worker(void* param){}
  
  void leech_worker(void* param){}

  void seed_worker(void* param){

    static uint16_t fileIndex = 0;

    if(!IS_CLIENT){

      // Finished
      if(fileIndex == 17){
        DISABLE_THREAD(DAEMON_SEED);
        return;
      }

      pieceBuffer.index = fileIndex++ * xTorrent.pieceSize;
      pieceBuffer.count = xTorrent.pieceSize;
      pieceBuffer.sum = hash((uint8_t*) &sensorData[0], pieceBuffer.count);
      pieceBuffer.tid = 0xBEEF;

      memcpy(&pieceBuffer.piece, &sensorData[pieceBuffer.index], pieceBuffer.count);
      
      call Debug.sendString("Send Piece: ");
      call Debug.sendNum(fileIndex,10);
      call Debug.sendByte('\n');
      
      call Message.sendPiece(&xPeer1.addr, &pieceBuffer);

    }
  }

  task void vMainLoop_Task(void){
  
    static uint16_t usLoopPasses = 0x0;
    
   //////////////////////////////////////////////////////////// 
   // Idle Daemon Process
    if (THREAD_ENABLED(DAEMON_IDLE))
      if( usLoopPasses % g_ucDaemonPriority[DAEMON_IDLE] == 0){
        idle_worker(NULL);
      }

   //////////////////////////////////////////////////////////// 
   // Scrape Daemon Process
    if (THREAD_ENABLED(DAEMON_SCRAPE))
      if((usLoopPasses % g_ucDaemonPriority[DAEMON_SCRAPE]) == 0){
        scrape_worker(NULL);
      }

   //////////////////////////////////////////////////////////// 
   // Announce Daemon Pass
    if (THREAD_ENABLED(DAEMON_ANNOUNCE))
      if( usLoopPasses % g_ucDaemonPriority[DAEMON_ANNOUNCE] == 0){
        announce_worker(NULL);
      }
      
   //////////////////////////////////////////////////////////// 
   // Leech Daemon Pass
    if (THREAD_ENABLED(DAEMON_LEECH))
      if( usLoopPasses % g_ucDaemonPriority[DAEMON_LEECH] == 0){
        leech_worker(NULL);
      }

   //////////////////////////////////////////////////////////// 
   // Seed Daemon Pass
    if (THREAD_ENABLED(DAEMON_SEED))
      if( usLoopPasses % g_ucDaemonPriority[DAEMON_SEED] == 0){
        seed_worker(NULL);
      }

    usLoopPasses++;

    // Re-post main task to simulate low priority thread,
    // one shot here to slow loop pass rate if necessary
    call Timer.startOneShot(512);
  }

  event void Message.recvScrapeResponse(torrent_t* torrent){
  
    if(IS_CLIENT){

      // Copy torrent meta
      memcpy((void*) &xTorrent, (void*) torrent, sizeof(torrent_t)); 

      // Grab source peer
      memcpy((void*) &xPeer1.addr, (void*) &torrent->source, sizeof(addr_t));

      xPeer1.peerId = hash((uint8_t*) &xPeer1.addr, sizeof(addr_t));

      call Debug.sendString("\r\n============= Found Torrent ============\r\n");

      call Debug.sendString("  Torrent ID: ");
      call Debug.sendNum((long)(0xBEEF),10);
      call Debug.sendByte('\n');

      call Debug.sendString("  Piece Size: ");
      call Debug.sendNum((long)(torrent->pieceSize),10);
      call Debug.sendByte('\n');

      call Debug.sendString("  Total Pieces: ");
      call Debug.sendNum((long)(torrent->pieces),10);
      call Debug.sendByte('\n');

      call Debug.sendString("  Total Size: ");
      call Debug.sendNum((long)(torrent->pieces*torrent->pieceSize),10);
      call Debug.sendByte('\n');

      call Debug.sendString("\r\n  Handshake Source Peer\n");

      //ENABLE_THREAD(DAEMON_ANNOUNCE);
      //ENABLE_THREAD(DAEMON_LEECH);
      
      call Debug.sendString("\r\n=============== Leeching ===============\r\n");

      call Message.handshake(&torrent->source, &xThisPeer);
    }

    DISABLE_THREAD(DAEMON_SCRAPE);
  }

  event void Message.recvAnnounceResponse(peer_t* peer){

    //TODO add to peer list then handshake peer

    if(!pxPeerTableWalk(peer->peerId)){

      vPeerTableAdd(peer);

      call Message.handshake(&peer->addr, &xThisPeer);
    }

  }

  event void Message.recvHandShake(hash_t peerId, peer_t* peerInfo){
  
    //NOTE source
  
    call Debug.sendString("Handshake Received!\n");

    memcpy((void*) &xPeer1, (void*) peerInfo, sizeof(peer_t));

    call Debug.sendString("Greetings: ");
    call Debug.sendNum((long)xPeer1.peerId,10);
    call Debug.sendByte('\n');
  
    call Debug.sendString("\r\n================ Seeding ===============\r\n");

    ENABLE_THREAD(DAEMON_SEED);
  }
  
  event void Message.recvInterest(hash_t peerId, bitvector_t* pieces){ }

  event void Message.recvPiece(hash_t peerId, piece_t* piece){

    static uint8_t pieces = 0;

    int i = 0;

    long* longPtr = (long*) fileBuffer;

    hash_t sum = hash((uint8_t*) piece->piece, piece->count);
  
    /*
    call Debug.sendString("Piece Received! [");

    call Debug.sendNum(piece->index,10);
    call Debug.sendByte(',');
    call Debug.sendNum(piece->count,10);
    call Debug.sendByte(',');
    call Debug.sendNum(piece->sum,10);
    call Debug.sendByte(',');
    call Debug.sendNum(piece->tid,10);
    call Debug.sendByte(']');
    */

    //if(piece->sum != sum) call Debug.sendString(" hash fail!");

    call Debug.sendByte('#');

    memcpy(&fileBuffer[piece->index], piece->piece, piece->count);

    if(++pieces == (xTorrent.pieces-1)){

      call Debug.sendString(" 100%\r\n");

      for(i = 0; i < 512; i++){ 

        call Debug.sendNum(longPtr[i], 10);
        call Debug.sendByte(' ');

      }

      call Debug.sendString("\r\n\r\nDownload Finished!\n"); 

      DISABLE_THREAD(DAEMON_LEECH);
      DISABLE_THREAD(DAEMON_SEED);

      //ENABLE_THREAD(DAEMON_IDLE);
    }
  }

  // Tracker Events
  event void Message.recvScrapeRequest(addr_t* from, torrent_t* torrent){}

  event void Message.recvAnnounceRequest(addr_t* from){}

  event void Timer.fired() {

    post vMainLoop_Task();
  }

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  //event void RadioControl.startDone(error_t e) { }
  //event void RadioControl.stopDone(error_t e) { }

}

