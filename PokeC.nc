#include <lib6lowpan/6lowpan.h>
#include <icmp6.h>

configuration PokeC {

    provides interface Poke;

} implementation {

    components PokeP;
    components new TimerMilliC();
    components ICMPPingC;

    Poke = PokeP.Poke;

    PokeP.TimeoutTimer -> TimerMilliC;

    PokeP.ICMPPing -> ICMPPingC.ICMPPing[unique("PING")];

}
