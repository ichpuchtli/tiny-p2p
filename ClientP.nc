#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

module ClientP {

  uses interface Boot;
  uses interface Timer<TMilli>;

  uses interface UDP as Echo;
  uses interface Leds;

  // Radio Comm
  uses interface SplitControl as RadioControl;

  // Serial Comm
  uses interface Debug;

  // Sensor Data
  //uses interface FileSystem as Files;
  

} implementation {

  //////////////////////////////////////////////////////////////////////////////
  // Boot
  event void Boot.booted() {

    call Timer.startPeriodic(1024);

    call RadioControl.start();

    call Echo.bind(7);
  }

  event void Echo.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta) {
    call Echo.sendto(from, data, len);
  }

  event void Timer.fired() {

    call Debug.sendString("Hello World!\r\n");
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  event void RadioControl.startDone(error_t e) { }
  event void RadioControl.stopDone(error_t e) { }
}
