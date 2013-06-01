#include <lib6lowpan/6lowpan.h>

configuration ClientAppC { 

} implementation {

  components ClientP;

  components MainC;
  ClientP.Boot -> MainC;

  // ADC0 Differential Mode
  components new MicrophoneC(ATM128_ADC_DIFF_ADC01_1x);
  ClientP.MicSensor -> MicrophoneC;

  components new TimerMilliC();
  ClientP.MainSched -> TimerMilliC;

  components LedsC;
  ClientP.Leds -> LedsC;

  components DebugC;
  ClientP.Debug -> DebugC.Debug;

  components P2PMessageC;
  ClientP.Message -> P2PMessageC.P2PMessage;

  /* TODO Don't know why but we have to include this module */
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

