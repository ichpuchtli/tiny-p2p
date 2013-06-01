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
  uses interface Timer<TMilli> as MainSched;

  uses interface Leds;

  // Radio Comm
  //uses interface SplitControl as RadioControl;

  // p2p message protocol
  uses interface P2PMessage as Message;

  // Serial Comm
  uses interface Debug;

  // Sensor Data
  uses interface Read<uint16_t> as MicSensor;
  //uses interface FileSystem as Files;
  
  // Poke, sync ping service 
  //uses interface Poke;

} implementation {

  task void vMainLoop_Task(void);

  volatile uint16_t g_usEnableDaemon = 1 << DAEMON_IDLE;

  volatile uint8_t g_ucDaemonPriority[5] = {0};

  peer_t xThisPeer;
  tracker_t xTracker;
  session_t xSession;
  torrent_t xTorrent;

  uint8_t pucFileBuffer[MAX_TORRENT_SIZE];

  // Boot
  event void Boot.booted() {

    call Debug.sendString("Initializing Peer Structure...");

    // Initialize Peer Structure
    xThisPeer.addr.port = htons(P2PMESSAGE_PORT);

    inet_pton6("fec0::", (struct in6_addr*) &xThisPeer.addr.addr);

    /* TODO use memory hack here struct in6_addr cannot be found
    struct in6_addr tmpaddress = (struct in6_addr) xThisPeer.addr.addr;
    tmpaddress.in6_u.u6_addr16[7] = (((uint16_t )TOS_NODE_ID << 8) | ((uint16_t )TOS_NODE_ID >> 8)) & 0xffff;
    */

    xThisPeer.peerId = hash((uint8_t*) &xThisPeer.addr, sizeof(addr_t));

    vBitVectorSetAll(&xThisPeer.interests);

    vBitVectorClearAll(&xThisPeer.completed);

    call Debug.sendString("Peer Addr: fec0::");
    call Debug.sendNum(TOS_NODE_ID);
    call Debug.sendCRLF();
    call Debug.sendString("Peer Port: " xstr(P2PMESSAGE_PORT));
    call Debug.sendCRLF();
    call Debug.sendString("Peer ID: ");
    call Debug.sendNum((int16_t) xThisPeer.peerId);
    call Debug.sendCRLF();

    call Debug.sendString("Poking Tracker...\r\n");

    xTracker.addr.port = htons(TRACKER_PORT);

    inet_pton6(TRACKER_ADDR_STR, (struct in6_addr*) &xTracker.addr.addr);

    xTracker.id = hash((uint8_t*) &xTracker.addr ,sizeof(addr_t));

    // Continually ping the tracker until we got a response. 
    //while(call Poke.poke(&xTracker.addr.addr, 2048) == 2048);

    /* Session Structure */
    call Debug.sendString("Initializing Session Structure...\r\n");

    memset((void*) &xSession, '\0', sizeof(session_t)); 

    call Debug.sendString("Booted!\r\n");

    g_ucDaemonPriority[DAEMON_IDLE] = 0;
    g_ucDaemonPriority[DAEMON_SCRAPE] = 0;

    g_usEnableDaemon = (1 << DAEMON_IDLE) | (1 << DAEMON_SCRAPE);

    call MainSched.startOneShot(100);

  }

  task void vMainLoop_Task(void){
  
    static uint16_t usMainLoopPasses = 0x0;

   //////////////////////////////////////////////////////////// 
   // Idle Daemon Process

    if( usMainLoopPasses %  g_ucDaemonPriority[DAEMON_IDLE] == 0){ 

      //TODO Idle work maybe flush streams, check pending responses etc.
      //TODO maybe ping tracker

      call Debug.sendString("IDLE: Running Threads (");

      if ( g_usEnableDaemon & (1 << DAEMON_SCRAPE ))
        call Debug.sendString("Scrape,");

      if ( g_usEnableDaemon & (1 << DAEMON_ANNOUNCE ))
        call Debug.sendString("Announce,");

      if ( g_usEnableDaemon & (1 << DAEMON_LEECH ))
        call Debug.sendString("Leech,");

      if ( g_usEnableDaemon & (1 << DAEMON_SEED ))
        call Debug.sendString("Seed,");

      call Debug.sendString(")\r\n");

    }

   //////////////////////////////////////////////////////////// 
   // Scrape Daemon Process

    if ( g_usEnableDaemon & (1 << DAEMON_SCRAPE )){

      
      if( usMainLoopPasses %  g_ucDaemonPriority[DAEMON_SCRAPE] == 0){ 

        //TODO Check for pending scrape responses before issuing any more
        call Message.scrape(&xTracker.addr,NULL);
        
      }
  
    }

   //////////////////////////////////////////////////////////// 
   // Announce Daemon Pass
   
    if ( g_usEnableDaemon & (1 << DAEMON_ANNOUNCE )){

      if( usMainLoopPasses % g_ucDaemonPriority[DAEMON_ANNOUNCE] == 0){ 

        call Message.announce(&xTracker.addr);

      }

    }
      
   //////////////////////////////////////////////////////////// 
   // Leech Daemon Pass
    
    if ( g_usEnableDaemon & (1 << DAEMON_LEECH )){

      if( usMainLoopPasses % g_ucDaemonPriority[DAEMON_LEECH] == 0){ 

        //vRequestRaresetPiece();
        //vSendRequestedPiece();

      }
    }

   //////////////////////////////////////////////////////////// 
   // Seed Daemon Pass

    if ( g_usEnableDaemon & (1 << DAEMON_SEED )){

      if( usMainLoopPasses %  g_ucDaemonPriority[DAEMON_SEED] == 0){ 

        //vSendRequestedPiece();

      }
    }

    usMainLoopPasses++;

    // Re-post main task to simulate low priority thread,
    // one shot here to slow loop pass rate if necessary
    call MainSched.startOneShot(100);
  }

  
  event void Message.recvScrapeResponse(torrent_t* torrent){
  
    //TODO Check tracker response and step the fsm if applicable
    //TODO maybe change function arg to torrent_t*

    if(torrent){

      memcpy((void*) &xTorrent, (void*) torrent, sizeof(torrent_t)); 

    }

  }

  event void Message.recvAnnounceResponse(peer_t* peer){
  
    //TODO add to peer list then handshake peer

    if(!pxPeerTableWalk(peer->peerId)){

      vPeerTableAdd(peer);

      call Message.handshake(&peer->addr, &xThisPeer);
    }

  }

  event void Message.recvHandShake(hash_t peerId, peer_t* peerInfo){}
  
  event void Message.recvInterest(hash_t peerId, bitvector_t* pieces){ }

  event void Message.recvPiece(hash_t peerId, piece_t* piece){ }

  // Tracker Events
  event void Message.recvScrapeRequest(hash_t peerId, torrent_t* torrent){}

  event void Message.recvAnnounceRequest(hash_t peerId){}

  event void MainSched.fired() {

    post vMainLoop_Task();
  }

  event void MicSensor.readDone(error_t result, uint16_t data) 
  {

    /*
    int16_t signedData;
    static uint16_t index = 0;
      
    signedData = (int16_t) (data << 6);
    
    if(index < MIC_DATA_BUFSIZE){
      dataBucket[index++] = signedData;
    }else{
      index = 0;
      cMicDataReady = 1;
    }
    */
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  //event void RadioControl.startDone(error_t e) { }
  //event void RadioControl.stopDone(error_t e) { }

}

