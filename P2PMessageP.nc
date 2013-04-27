
module P2PMessageP {

  provides interface P2PMessage;
  provides interface Init;

  uses interface UDP as MesgSock;
  uses interface StdControl as SocketCtrl;
  uses interface ICMPPing;


} implementation {

  command error_t Init.init(){

    call SocketCtrl.start();
    
    return SUCCESS;

  }

  event void MesgSock.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {

    message_packet_t mesg = (message_packet_t) data;

    uint8_t* payload = &mesg.payload;
    size_t len = &mesg.len;

    //hash_t peerId = hash((uint8_t*) from, sizeof(struct sockaddr_in6));

    switch(mesg.type){

      case MESSEGE_PIECE:
        signal P2PMessage.recvPeice(peerId, (peice_t*) payload);
        break;

      case MESSEGE_PIECE_ACK:
        signal P2PMessage.recvPeiceAck(peerId, (peice_t*) payload);
        break;

      case MESSEGE_INTEREST:
        signal P2PMessage.recvInterest(peerId, (hash_t*) payload);
        break;

      case MESSEGE_INTEREST_ACK:
        signal P2PMessage.recvInterestAck(peerId, (peice_t*) payload);
        break;

      case MESSEGE_SCRAPE_RESPONSE:
        signal P2PMessage.recvScrapeResponse(peerId, (peice_t*) payload);
        break;

      case MESSEGE_ANNOUNCE_RESPONSE:
        signal P2PMessage.recvAnnounceResponse(peerId, (peice_t*) payload);
        break;

      case MESSEGE_HANSHAKE:
        signal P2PMessage.recvHandshake(peerId, (peice_t*) payload);
        break;

      case MESSEGE_HANSHAKE_RESPONSE:
        signal P2PMessage.recvHandshakeResponse(peerId, (peice_t*) payload);
        break;

      default: break;
        signal P2PMessage.recvUnknownMesg(peerId, (peice_t*) payload);
        break;


    }


  }

  async command void sendMessage(hash_t* peer, message_t type, uint8_t* payload, size_t count){

    //TODO Construct Address and Port structures
    //TODO Construct Payload

    uint8_t buffer[1024];

    struct sockaddr_in6 addr; //addr = hash_lookup(peer, swarm)

    message_packet_t* mesg = (message_packet_t*) buffer;

    mesg.type = type;
    mesg.len = count;

    memcpy(&mesg.payload, payload, mesg.len);

    call MesgSock.sendto(addr, mesg , mesg.len + sizeof(message_t) + sizeof(size_t));

  }

  // Similar to Ping just checks for a response; payload ignored 
  async command void ping(hash_t* peerId){

    //TODO Construct Address and Port structures
    //TODO Ping Address

    call ICMPPing.ping(&dest, 1024, 10);
  }

  event void ICMPPing.pingReply(struct in6_addr *source, struct icmp_stats *stats) {
    int len;
    len = inet_ntop6(source, reply_buf, MAX_REPLY_LEN);
    if (len > 0) {
      len += snprintf(reply_buf + len - 1, MAX_REPLY_LEN - len + 1, ping_fmt,
                      stats->seq, stats->ttl, stats->rtt);
      reply_buf[len] = '\0';
      call UDP.sendto(&session_endpoint, reply_buf, len);
    }
  }

  event void ICMPPing.pingDone(uint16_t ping_rcv, uint16_t ping_n) {
    int len;
    len = snprintf(reply_buf, MAX_REPLY_LEN, ping_summary, ping_n, ping_rcv);
    call UDP.sendto(&session_endpoint, reply_buf, len);
  }
  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  // Who you are (PeerID) , what your after(torrent_t{bitvector,sha1}), what port you listen on(port_t), etc..
  async command void handshake(hash_t* peerId){ }

  // Ask the tracker for information about a torrent, tracker load, swarm status etc..
  async command void scrape(torrent_t* meta){
    //call P2PMessage.sendMessage(TRACKER_ID, MESSAGE_SCRAPE, (uint8_t*) meta, META_SIZE);
  }

  // Acknowledge your presents in the p2p network and ask for peers
  async command void announce(void){}

  // Send a piece to an address
  async command void sendPiece(hash_t* peerId, peice_t* piece){
    call P2PMessage.sendMessage(peerId, MESSAGE_PIECE, (uint8_t*) piece, PIECE_SIZE);
  }

  // Request a peice from an address; not sure when or if this mechanism will be used
  // Use a zero len piece to signal peice request
  async command void sendInterest(hash_t* peerId, hash_t* pieceId){
    //call P2PMessage.sendMessage(peerId, MESSAGE_INTEREST, (uint8_t*) pieceId, ulHashSize(pieceId));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Tasks

  //////////////////////////////////////////////////////////////////////////////
  // Unused Events
  event void SocketCtrl.startDone(error_t e) { }
  event void SocketCtrl.stopDone(error_t e) { }
