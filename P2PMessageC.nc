#include <lib6lowpan/6lowpan.h>
#include "P2PMessage.h"

configuration P2PMessageC
{
  provides interface P2PMessage;
}

implementation
{
  
  components P2PMessageP;
  
  P2PMessage = P2PMessageP.P2PMessage;

  components MainC;
  MainC.SoftwareInit -> P2PMessageP.Init;

  components new UdpSocketC();
  P2PMessageP.MesgSock -> UdpSocketC.UDP;

  //components DebugC;
  //P2PMessageP.Debug -> DebugC.Debug;

  //components ICMPPingC;
  //UDPShellP.ICMPPing -> ICMPPingC.ICMPPing[unique("PING")];

  /* TODO still don't know why this has to be included */
  components UDPShellC;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

#ifndef IN6_PREFIX
  components DhcpCmdC;
#endif

#if defined(PLATFORM_IRIS)
#warning *** RouterCmd disabled for IRSI ***
#else
  components RouteCmdC;
#endif

}
