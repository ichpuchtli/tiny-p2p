#include <lib6lowpan/6lowpan.h>
#include <lib6lowpan/ip.h>
#include <icmp6.h>

interface Poke {

    // Uses ICMPPing, ping target and wait for reply.
    // Returns the minimum between the ping time and the timeout
    command uint16_t poke(struct in6_addr* target, uint16_t timeout);
}
