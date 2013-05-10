
module DebugP {

  provides interface Debug;
  provides interface Init;

  uses interface UartByte;
  uses interface StdControl as UartControl;

} implementation {


  void reverse(char* str, int length){

    int i = 0, j = length-1;
    char tmp;

    while(i < j){

      tmp = str;

      str[i] = str[j];
      str[j] = tmp;

      i++;
      j--;

    }

  }

  // itoa implementation from K&R
  int itoa(int n, char* out){

    // if negative, need 1 char for sign
    int sign = n < 0 ? 1 : 0;
    int i = 0;
    if( n == 0 ){
      out[i++] = '0';
    }else if (n < 0){
      out[i++] = '-';
      n = -n;
    }
    
    while (n > 0) {
      out[i++] = '0' + n % 10;
      n /= 10;
    }

    out[i] = '\0';
    reverse(out + sign, i - sign);

    return i - sign;
  }

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

  async command void Debug.sendNum(int16_t num){

    char buffer[8];
    uint8_t len = 0;

    len = itoa(num, buffer);

    // ignore the trailing '\0'
    call Debug.sendStream(buffer, len - 1); 
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

  async command uint8_t Debug.num2Str(uint16_t num, char* buf){ }

  async command void Debug.flush(void){ }

}
