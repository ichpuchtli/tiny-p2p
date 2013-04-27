
configuration P2PMessageC
{
  provides interface P2PMessage;
}

implementation
{
  
  components P2PMessageP;
  
  P2PMessage = P2PMessageP.P2PMessage;;

  components MainC;
  MainC.SoftwareInit -> P2PMessageP.Init;

  components ICMPPingC;
  UDPShellP.ICMPPing -> ICMPPingC.ICMPPing[unique("PING")];
}
