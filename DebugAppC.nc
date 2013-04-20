
configuration DebugAppC
{
  provides interface Debug;
}

implementation
{
  
  components DebugP;
  
  Debug = DebugP.Debug;

  components Atm128Uart0C;
  DebugP.UartControl -> Atm128Uart0C.StdControl;

  components MainC;
  MainC.SoftwareInit -> DebugP.Init;
}


