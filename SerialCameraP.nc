
#define CHUNK_SIZE 64

module SerialCameraP {

  provides interface SerialCamera;

  provides interface Init;

  uses interface StdControl as UartControl;

  uses interface UartStream;

}

implementation {

  uint8_t resetCommand[4] = {0x56,0x00,0x26,0x00};        //Reset command

  uint8_t captureCommand[5] = {0x56,0x00,0x36,0x01,0x00};  //Take picture command

  uint8_t getLenCommand[5] = {0x56,0x00,0x34,0x01,0x00};   //Read JPEG file size command

  uint8_t getDataCommand[16] = { 0x56,0x00,0x32,0x0c,0x00,0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x64,0x00,0x0a};

  uint8_t cmdConti[5] = {0x56,0x00,0x36,0x01,0x02};   //Take next picture command


  uint16_t g_offset = 0;

  command error_t Init.init() {

    call UartControl.start();

    call UartStream.send(resetCommand, 4);

    return SUCCESS;
  }
  

  async command void SerialCamera.capture(void){
    call UartStream.send(captureCommand, 5);
  }


  async command void SerialCamera.read(uint16_t offset) {
    
    g_offset = offset;

    getDataCommand[8] = offset >> 8;
    getDataCommand[9] = offset & 0xFF;

    call UartStream.send(getDataCommand, 16);
  }


  /**
   * Signals the receipt of a byte.
   * @param byte The byte received.
   */
  async event void UartStream.receivedByte( uint8_t byte ) {

    static uint8_t imageBuffer[CHUNK_SIZE];

    static uint8_t imagePosition = 0;
    static uint8_t bufferPosition = 0;

    static uint8_t readmode = 0;
    static uint8_t previousByte = '\0';

    if (previousByte == 0xFF && byte == 0xD8 && readmode == 0) {
      //image payload starts
      imagePosition = 0;
      readmode = 1; //start reading image
    }

    if (previousByte == 0xFF && byte == 0xD9) {
      readmode = 0; //stop reading image

      signal SerialCamera.readDone((uint16_t) g_offset, (uint8_t*) imageBuffer);
    }

    if (readmode == 1) {
      imageBuffer[imagePosition++] = byte;
    }
    previousByte = byte;
  }


  async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ) { }

  async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ){}
}

