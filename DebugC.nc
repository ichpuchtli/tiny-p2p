
configuration DebugC
{
  provides interface Debug;
}

implementation
{
  
  components DebugP;
  
  Debug = DebugP.Debug;

  components Atm128Uart0C;
  DebugP.UartControl -> Atm128Uart0C.StdControl;
  DebugP.UartByte -> Atm128Uart0C.UartByte;

  components MainC;
  MainC.SoftwareInit -> DebugP.Init;
}


