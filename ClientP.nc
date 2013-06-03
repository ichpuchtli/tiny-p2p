#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

#include "tracker.h" //TRACKER_PORT, TRACKER_ADDR_STR, tracker_t
#include "peer.h" // pxPeerTable[], pxPeerTableWalk(peer_t), peer_t
#include "session.h"
#include "P2PMessage.h" // P2PMESSAGE_PORT
#include "bitvector.h"

#define DEFAULT_PKT_SIZE 256

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


  // Sensor Data
  uses interface Read<uint16_t> as MicSensor;
  //uses interface FileSystem as Files;
  
  // Poke aka Ping, sync ping service 
  //uses interface Poke;

} implementation {

  volatile uint16_t g_usEnableDaemon = 1 << DAEMON_IDLE;

  volatile uint8_t g_ucDaemonPriority[5] = {0};

  peer_t xThisPeer;
  tracker_t xTracker;

  struct sockaddr_in6 tracker;

  // Boot
  event void Boot.booted() {

    call Debug.sendString("\n============== Boot Sequence ===========\r\n");

    // Initialize Peer Structure
    xThisPeer.addr.port = htons(P2PMESSAGE_PORT);
    inet_pton6("fec0::2", (struct in6_addr*) &xThisPeer.addr.addr);

    xThisPeer.peerId = hash((uint8_t*) &xThisPeer.addr, sizeof(addr_t));

    vBitVectorSetAll(&xThisPeer.interests);
    vBitVectorClearAll(&xThisPeer.completed);

    call Debug.sendString("Peer Addr: fec0::");
    call Debug.sendNum(TOS_NODE_ID,10);
    call Debug.sendByte('\n');
    call Debug.sendString("Peer Port: " xstr(P2PMESSAGE_PORT));
    call Debug.sendByte('\n');
    call Debug.sendString("Peer ID: ");
    call Debug.sendNum(xThisPeer.peerId, 10);
    call Debug.sendCRLF();

    call Debug.sendString("Connecting to Tracker...\r\n");

    xTracker.addr.port = htons(TRACKER_PORT);
    inet_pton6(TRACKER_ADDR_STR, (struct in6_addr*) &xTracker.addr.addr);
    xTracker.id = hash((uint8_t*) &xTracker.addr ,sizeof(addr_t));

    call Debug.sendString("Tracker Addr: " TRACKER_ADDR_STR);
    call Debug.sendByte('\n');
    call Debug.sendString("Tracker Port: " xstr(TRACKER_PORT));
    call Debug.sendByte('\n');
    call Debug.sendString("Tracker ID: ");
    call Debug.sendNum(xTracker.id, 10);
    call Debug.sendCRLF();

    // Continually ping the tracker until we got a response. 
    //while(call Poke.poke(&xTracker.addr.addr, 2048) == 2048)
      //call Debug.sendByte('.');

    g_ucDaemonPriority[DAEMON_IDLE] = 10;
    g_ucDaemonPriority[DAEMON_SCRAPE] = 5;

    g_usEnableDaemon = (1 << DAEMON_SCRAPE);

    call Timer.startOneShot(2024);

    call Debug.sendString("============== Main Task ===============\r\n");

  }

  task void vMainLoop_Task(void){
  
    static uint16_t usMainLoopPasses = 0x0;
    
   //////////////////////////////////////////////////////////// 
   // Idle Daemon Process

    if( usMainLoopPasses % g_ucDaemonPriority[DAEMON_IDLE] == 0){ 

      //TODO Idle work maybe flush streams, check pending responses etc.
      //TODO maybe ping tracker
      
      call Debug.sendString("Main (");
      call Debug.sendNum(usMainLoopPasses,10);
      call Debug.sendString(")\r\n");

    }

   //////////////////////////////////////////////////////////// 
   // Scrape Daemon Process

    if ( g_usEnableDaemon & (1 << DAEMON_SCRAPE )){
      
      if((usMainLoopPasses % g_ucDaemonPriority[DAEMON_SCRAPE]) == 0){ 

        //TODO Check for pending scrape responses before issuing any more
        //TODO If we are the sensor client we need to send a torrent here when we have captured a picture
        call Message.scrape(&xTracker.addr,NULL);
        
      }
  
    }

   //////////////////////////////////////////////////////////// 
   // Announce Daemon Pass
   
    if ( g_usEnableDaemon & (1 << DAEMON_ANNOUNCE )){

      if( usMainLoopPasses % g_ucDaemonPriority[DAEMON_ANNOUNCE] == 0){ 

        //call Message.announce(&xTracker.addr);

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
    call Timer.startOneShot(10);
  }

  event void Message.recvScrapeResponse(torrent_t* torrent){
  
    call Debug.sendString("Tracker Responded\r\n");
  }

  event void Message.recvAnnounceResponse(peer_t* peer){ }

  event void Message.recvHandShake(hash_t peerId, peer_t* peerInfo){}
  
  event void Message.recvInterest(hash_t peerId, bitvector_t* pieces){ }

  event void Message.recvPiece(hash_t peerId, piece_t* piece){ }

  // Tracker Events
  event void Message.recvScrapeRequest(addr_t* from, torrent_t* torrent){}

  event void Message.recvAnnounceRequest(addr_t* from){}

  event void Timer.fired() {

    post vMainLoop_Task();
      //call Message.sendMessage((addr_t*) &peer1, MESSAGE_PIECE, (uint8_t*) &xMicDataPacket , sizeof(struct tmpPacket));
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

