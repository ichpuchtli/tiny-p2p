#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

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
  //uses interface FileSystem as Files;
  

} implementation {

  //////////////////////////////////////////////////////////////////////////////
  // Boot
  event void Boot.booted() {

    call Timer.startPeriodic(1024);

  }
  
  event void Message.recvScrapeResponse(tracker_t* trackerStatus){}

  event void Message.recvAnnounceResponse(peer_t* peer){}

  event void Message.recvHandShake(addr_t* addr, peer_t* peerInfo){}
  
  event void Message.recvInterest(peer_t* peer, bitvector_t* pieces){}

  event void Message.recvPiece(peer_t* peer, piece_t* piece){}

  event void Timer.fired() {

    call Debug.sendString("Hello World!\r\n");
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  //event void RadioControl.startDone(error_t e) { }
  //event void RadioControl.stopDone(error_t e) { }
}
