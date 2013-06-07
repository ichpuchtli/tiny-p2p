
interface SerialCamera {

  async command void capture(void);

  async command void read(uint16_t offset);

  async event void readDone(uint16_t offset, uint8_t* buffer);

}
