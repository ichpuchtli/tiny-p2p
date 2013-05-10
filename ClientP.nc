#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include <printf.h>

#define MIC_DATA_BUFSIZE 512

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

  volatile char cMicDataReady = 0;

  //////////////////////////////////////////////////////////////////////////////
  struct tmpPacket {
    p2p_header_t header;
    char array[MIC_DATA_BUFSIZE*2];
  } xMicDataPacket;
  
  int16_t* dataBucket = (int16_t*) xMicDataPacket.array;
  struct sockaddr_in6 peer1;

  // Boot
  event void Boot.booted() {

    call Timer.startPeriodic(8);

    call Debug.sendString("Booted!\r\n");
    
    peer1.sin6_port = htons(1300);
    inet_pton6("fec0::100", &peer1.sin6_addr);

    call Debug.sendString("New Peer: fec0::100 on port 1300!\r\n");
  }
  
  event void Message.recvScrapeResponse(tracker_t* trackerStatus){}

  event void Message.recvAnnounceResponse(peer_t* peer){}

  event void Message.recvHandShake(addr_t* addr, peer_t* peerInfo){}
  
  event void Message.recvInterest(peer_t* peer, bitvector_t* pieces){ }

  event void Message.recvPiece(peer_t* peer, piece_t* piece){ 

   /* struct tmpPacket* tmp = (struct tmpPacket*) piece;
  
    call Debug.sendStream(tmp->array, 10); */
  
  }

  event void Timer.fired() {

    if(cMicDataReady){

      call Debug.sendString("Microphone Data Dump Ready\r\n");

      call Debug.sendString("Throwing a piece at fec0::100 on port 1300\r\n");
  
      call Message.sendMessage((addr_t*) &peer1, MESSAGE_PIECE, (uint8_t*) &xMicDataPacket , sizeof(struct tmpPacket));

      cMicDataReady = 0;

    }else{
      call MicSensor.read();
    }
  }

  event void MicSensor.readDone(error_t result, uint16_t data) 
  {

    int16_t signedData;
    static uint16_t index = 0;
      
    signedData = (int16_t) (data << 6);
    
    if(index < MIC_DATA_BUFSIZE){
      dataBucket[index++] = signedData;
    }else{
      index = 0;
      cMicDataReady = 1;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  //event void RadioControl.startDone(error_t e) { }
  //event void RadioControl.stopDone(error_t e) { }

}

