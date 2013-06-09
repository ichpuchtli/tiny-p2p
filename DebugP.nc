
module DebugP {

  provides interface Debug;
  provides interface Init;

  uses interface UartByte;
  uses interface StdControl as UartControl;

} implementation {

  command error_t Init.init(){

    call UartControl.start();
    
    return SUCCESS;

  }

  async command void Debug.sendByte(char byte){
    call UartByte.send(byte);
  }

  async command void Debug.sendStream(char* byteStream, size_t len){
    while(len--) call Debug.sendByte(*byteStream++);
  }

  async command void Debug.sendString(char* byteString){
    call Debug.sendStream(byteString, call Debug.stringLen(byteString));
  }

  async command void Debug.sendNum(int16_t num, uint8_t radix){

    char buffer[32];

    (void) ltoa(num, buffer, radix);

    call Debug.sendString(buffer); 
  }

  async command void Debug.sendCRLF(){
    call Debug.sendByte('\r');
    call Debug.sendByte('\n');
  }
  
  async command size_t Debug.stringLen(char* byteString){

    size_t size = 0;

    while(*byteString++) size++;

    return size;
  }

  async command void Debug.flush(void){ }

}
