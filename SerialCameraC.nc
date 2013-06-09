configuration SerialCameraC {

  provides interface SerialCamera;

} implementation {

  components SerialCameraP;
  SerialCamera = SerialCameraP.SerialCamera;

  components MainC;
  MainC.SoftwareInit -> SerialCameraP.Init;


  components PlatformSerial1C;

  components PlatformSerialC;
  SerialCameraP.UartStream -> PlatformSerial1C.UartStream;
  SerialCameraP.UartControl -> PlatformSerial1C.StdControl;

}


