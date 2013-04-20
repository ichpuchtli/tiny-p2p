
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

  async command void Debug.sendNum(uint16_t num){

    char buffer[8];

    call Debug.sendStream(buffer, call Debug.num2Str(num,buffer));
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

  async command int16_t Debug.str2Num(char* string){

    int16_t value = 0;

    while( *string >= '0' && *string <= '9' ){
      value *= 10;
      value += (int16_t) (*string - '0');
      string++;
    }

    return value;

  }

  async command uint8_t Debug.num2Str(uint16_t num, char* buf){

    uint16_t i = 8;
    uint8_t j = 0;

    for(; num && i; --i, num /= 10) buf[i] = "0123456789"[num % 10];

    for(; j < (8 - (i+1)); j++){
      buf[j] = buf[i+1+j];
    }

    return j;
  }

  async command void Debug.flush(void){ }

}
