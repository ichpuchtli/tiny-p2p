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

  FSM_IDLE = 0,
  FSM_ANNOUCE,
  FSM_LEECH,
  FSM_SEED
}


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
  
  // Poke, sync ping service 
  //uses interface Poke;

} implementation {

  task void vStateMachinePass_Task(void);

  peer_t xThisPeer;
  tracker_t xTracker;
  session_t xSession;
  torrent_t xTorrent;

  static volatile uint8_t ucFSMState = 0;

  // Boot
  event void Boot.booted() {

    call Debug.sendString("Initializing Peer Structure...");

    // Initialize Peer Structure
    xThisPeer.addr.port = htons(P2PMESSAGE_PORT);

    inet_pton6("fec0::", (struct in6_addr*) &xThisPeer.addr.addr);
    ((struct in6_addr) xThisPeer.addr.addr).in6_u.u6_addr16[7] =
    (((uint16_t )TOS_NODE_ID << 8) | ((uint16_t )TOS_NODE_ID >> 8)) & 0xffff;

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
    memset((void*) xSession, '\0', sizeof(session_t)); 

    call Debug.sendString("Booted!\r\n");

    call Timer.startPeriodic(1024);

    post vStateMachinePass_Task();

  }


  task void vStateMachinePass_Task(void){


    switch(ucState){

      case FSM_IDLE: // Sraping
        call P2PMessage.scrape(NULL);
        return;

      case FSM_ANNOUCE: // Announcing
        call P2PMessage.announce();
        return;

      case FSM_LEECH: // Leeching

        if(fileCompleted){
          ucStage++;
        }else{

          vRequestRaresetPiece();
          vSendRequestedPiece();
        }

        goto PRESERVE;

      case FSM_SEED: // Seeding

        vSendRequestedPiece();

        goto PRESERVE;

      }

PRESERVE:
    // Push State Machine State then exit
    post vStateMachinePass_Task();


  }

  
  event void Message.recvScrapeResponse(tracker_t* trackerStatus){
  
    //TODO Check tracker response and step the fsm if applicable
    //TODO maybe change function arg to torrent_t*

    if(trackerStatus->torrent){ // TODO This is not good indicator for ready torrent
      memcpy((void*) &xTorrent, (void*) trackerStatus->torrent, sizeof(torrent_t)); 
    }

    post vStateMachinePass_Task();
  }

  event void Message.recvAnnounceResponse(peer_t* peer){
  
    //TODO add to peer list then handshake peer

    if(!pxPeerTableWalk(peer->id)){

      vPeerTableAdd(peer);

      call P2PMessage.handshake(peer->addr);
    }

    post vStateMachinePass_Task();
  
  }

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

