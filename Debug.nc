
interface Debug {

  async command void sendByte(char byte);

  async command void sendStream(char* byteStream, size_t len);

  async command void sendString(char* byteString);

  async command void sendNum(uint16_t num);

  async command void sendCRLF(void);
  
  async command size_t stringLen(char* byteString);

  async command int16_t str2Num(char* string);

  async command uint8_t num2Str(uint16_t num, char* buf);

  async command void flush(void);

}
