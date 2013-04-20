
#include <lib6lowpan/6lowpan.h>

configuration ClientAppC { 

} implementation {

  components ClientP;

  components MainC;
  ClientP.Boot -> MainC;

  components new TimerMilliC();
  ClientP.Timer -> TimerMilliC;

  components LedsC;
  ClientP.Leds -> LedsC;

  components IPStackC;
  ClientP.RadioControl -> IPStackC.SplitControl;

  components new UdpSocketC();
  ClientP.Echo -> UdpSocketC.UDP;

  components DebugC;
  ClientP.Debug -> DebugC.Debug;

  /* Don't know why but we have to include this module */
  components UDPShellC;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

#ifndef  IN6_PREFIX
  components DhcpCmdC;
#endif

#if defined(PLATFORM_IRIS)
#warning *** RouterCmd disabled for IRIS ***
#else
  components RouteCmdC;
#endif
}

