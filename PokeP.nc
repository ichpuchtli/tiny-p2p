#include <lib6lowpan/ip.h>
#include <IPDispatch.h>
#include <icmp6.h>

module PokeP {

    provides interface Poke;

    uses interface ICMPPing;
    uses interface Timer<TMilli> as TimeoutTimer; 

} implementation {

    volatile uint16_t g_ucReplyFlag;
    volatile uint16_t g_ulPingTime;

    command uint16_t Poke.poke(struct in6_addr* target, uint16_t timeout){

        // 200ms period, 1 ping
        call ICMPPing.ping(target, 200, 1);

        call TimeoutTimer.startOneShot(timeout);

        g_ucReplyFlag = 0;
        g_ulPingTime = timeout;

        while(g_ucReplyFlag == 0)
        {
            asm("nop");
        }

        return g_ulPingTime;

    }

    event void ICMPPing.pingReply(struct in6_addr* source, struct icmp_stats* ping_stats){

        g_ulPingTime = ping_stats->rtt;
        g_ucReplyFlag = 1;
    }

    event void TimeoutTimer.fired(){

        g_ucReplyFlag = 1;
    }

    event void ICMPPing.pingDone(uint16_t ping_rcv, uint16_t ping_n){}

}
