COMPONENT=ClientAppC
# uncomment this for network programming support
# BOOTLOADER=tosboot

# radio options
CFLAGS += -DCC2420_DEF_CHANNEL=11
CFLAGS += -DRF230_DEF_CHANNEL=11
CFLAGS += -DCC2420_DEF_RFPOWER=4 -DENABLE_SPI0_DMA

# use hardware ack
CFLAGS+=-DRF230_HARDWARE_ACK
CFLAGS+=-DCC2420_HW_ACKNOWLEDGEMENTS
CFLAGS += -DSOFTWAREACK_TIMEOUT=3000

# C Modules
CFLAGS += bitvector.c

# enable dma on the radio
# PFLAGS += -DENABLE_SPI0_DMA

# you can compile with or without a routing protocol... of course,
# without it, you will only be able to use link-local communication.
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(TOSDIR)/lib/net/rpl
# PFLAGS += -DRPL_OF_MRHOF

# tell the 6lowpan layer to not generate hc-compressed headers
#PFLAGS += -DLIB6LOWPAN_HC_VERSION=-1

# if you're using DHCP, set this to try and derive a 16-bit address
# from the IA received from the server.  This will work if the server
# gives out addresses from a /112 prefix.  If this is not set, blip
# will only use EUI64-based link addresses.  If not using DHCP, this
# causes blip to use TOS_NODE_ID as short address.  Otherwise the
# EUI will be used in either case.
PFLAGS += -DBLIP_DERIVE_SHORTADDRS

# this disables dhcp and statically chooses a prefix.  the motes form
# their ipv6 address by combining this with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# PFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED

include $(MAKERULES)

