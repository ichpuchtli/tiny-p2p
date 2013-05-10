#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include <printf.h>

#define MIC_DATA_BUFSIZE 16

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

  int16_t psMicData[MIC_DATA_BUFSIZE];
  volatile char cMicDataReady = 0;

  //////////////////////////////////////////////////////////////////////////////
  // Boot
  event void Boot.booted() {

    call Timer.startPeriodic(4);

    call Debug.sendString("Booted!\r\n");
  }
  
  event void Message.recvScrapeResponse(tracker_t* trackerStatus){}

  event void Message.recvAnnounceResponse(peer_t* peer){}

  event void Message.recvHandShake(addr_t* addr, peer_t* peerInfo){}
  
  event void Message.recvInterest(peer_t* peer, bitvector_t* pieces){}

  event void Message.recvPiece(peer_t* peer, piece_t* piece){}

  event void Timer.fired() {

    if(cMicDataReady){
      //TODO Update Piece BitVector
      //call Messagne.sendMessage();
      call Debug.sendString("Data Ready\r\n");
      cMicDataReady = 0;
    }else{
      call MicSensor.read();
    }

    //printf("Timer: %d\r\n", cMicDataReady);
    //printfflush();
  }

  event void MicSensor.readDone(error_t result, uint16_t data) 
  {

    int16_t signedData;
    static uint16_t index = 0;
      
    signedData = (int16_t) (data << 6);
    
    call Debug.sendString("Read\r\n");

    /*
    call Debug.sendString("Read");
    call Debug.sendByte((char) (index&0xFF));
    call Debug.sendString("\r\n");
    call Debug.sendByte((char) (data & 0xFF));
    call Debug.sendByte((char) (data >> 8));
    */

    //printf("Read[%d]: %d\r\n", index, signedData);
    //printfflush();
    
    if(index < MIC_DATA_BUFSIZE){
      psMicData[index++] = signedData;
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
