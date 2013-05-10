#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

#include "peer.h" // pxPeerTable[], pxPeerTableWalk(peer_t), peer_t

#define DEFAULT_PKT_SIZE 256

#define xstr(a) str(a)
#define str(a) #a

module ClientP {

  uses interface Boot;
  uses interface Timer<TMilli>;

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
  

} implementation {

  struct GenPacket {
    p2p_header_t header;
    char array[DEFAULT_PKT_SIZE];
  } xGenPacket;

  peer_t xThisPeer;
  tracker_t xTracker;

  // Boot
  event void Boot.booted() {

    call Debug.sendString("Initializing Peer Structure...");

    // Initialize Peer Structure
    xThisPeer.addr.port = htons(P2PMESSAGE_PORT);

    call Debug.sendByte('.');

    inet_pton6("fec0::" xstr(TOS_NODE_ID), &xThisPeer.addr.addr);

    call Debug.sendByte('.');

    xThisPeer.peerId = hash(xThisPeer.addr,sizeof(addr_t))

    call Debug.sendByte('.');

    vBitVectorSetAll(&xThisPeer.interested);

    call Debug.sendByte('.');

    vBitVectorClearAll(&xThisPeer.completed);

    call Debug.sendString("Done\r\n");

    call Debug.sendString("Peer Addr: fec0::" xstr(TOS_NODE_ID) "\r\n");
    call Debug.sendString("Peer Port: " xstr(P2PMESSAGE_PORT) "\r\nPeer ID: ");
    call Debug.sendNum((int16_t) xThisPeer.peerId)
    call Debug.sendCRLF();

    call Debug.sendString("Connecting to Tracker...");

    xTracker.addr.port = htons(TRACKER_PORT);

    call Debug.sendByte('.');

    inet_pton6(TRACKER_ADDR_STR, &xTracker.addr.addr);

    call Debug.sendByte('.');

    xTracker.id = hash(xTracker.addr,sizeof(addr_t))

    call Debug.sendByte('.');

    // Continually ping the tracker until we got a response. 
    //while(call Poke.poke(&xTracker.addr.addr, 2048) == 2048)
      //call Debug.sendByte('.');
  
    call Debug.sendString("Connected\r\n");

    call Debug.sendString("Initializing Session Structure...");

    //TODO Session Structure

    call Debug.sendString("Booted!\r\n");

    call Timer.startPeriodic(1024);

    post vStateMachinePass_Task();
  }

  task void vStateMachinePass_Task(void){

    static bool cIdle = TRUE;
    static uint8_t ucStage = 0;

/*

    switch(ucStage){

      case 0: // Sraping
       if(Scrape())
         ucStage++;
       goto PRESERVE;

      case 1: // Announcing
        if(peer_count < MAX_PEER_CONNECTIONS){
          announce();
        }else{
          ucStage++;
        }
       goto PRESERVE;

      case 2: // Leeching

        if(fileCompleted){
          ucStage++;
        }else{
          vRequestRaresetPiece();
          vSendRequestedPiece();
        }

        goto PRESERVE;

      case 3: // Seeding

        vSendRequestedPiece();

        goto PRESERVE;

      }

PRESERVE:
    // Push State Machine State then exit
    //post vStateMachinePass_Task();

*/

  }

  
  event void Message.recvScrapeResponse(tracker_t* trackerStatus){}

  event void Message.recvAnnounceResponse(peer_t* peer){}

  event void Message.recvHandShake(addr_t* addr, peer_t* peerInfo){}
  
  event void Message.recvInterest(peer_t* peer, bitvector_t* pieces){ }

  event void Message.recvPiece(peer_t* peer, piece_t* piece){ }

  event void Timer.fired() {

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

