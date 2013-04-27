
/* Peer2Tracker Related Messages */

/* Request information from the tracker, while sending information about ourself */
/*
'info_hash': This is a REQUIRED 20-byte SHA1 hash value. In order to obtain this value the peer must calculate the SHA1 of the value of the "info" key in the metainfo file.

'peer_id': This is a REQUIRED string and must contain the 20-byte self-designated ID of the peer.

'port': The port number that the peer is listening to for incoming connections from other peers. BTP/1.0 does not specify a standard port number, nor a port range to be used. This key is REQUIRED.

'uploaded': This is a base ten integer value. It denotes the total amount of bytes that the peer has uploaded in the swarm since it sent the "started" event to the tracker. This key is REQUIRED.

'downloaded': This is a base ten integer value. It denotes the total amount of bytes that the peer has downloaded in the swarm since it sent the "started" event to the tracker. This key is REQUIRED.

'left': This is a base ten integer value. It denotes the total amount of bytes that the peer needs in this torrent in order to complete its download. This key is REQUIRED.

'ip': This is an OPTIONAL value, and if present should indicate the true, Internet-wide address of the peer, either in dotted quad IPv4 format, hexadecimal IPv6 format, or a DNS name.

'numwant': This is an OPTIONAL value. If present, it should indicate the number of peers that the local peer wants to receive from the tracker. If not present, the tracker uses an implementation defined value.

'event': This parameter is OPTIONAL. If not specified, the request is taken to be a regular periodic request. Otherwise, it MUST have one of the three following values:

'started': The first HTTP GET request sent to the tracker MUST have this value in the "event" parameter.
'stopped':
This value SHOULD be sent to the tracker when the peer is shutting down gracefully.
'completed': This value SHOULD be sent to the tracker when the peer completes a download. The peer SHOULD NOT send this value if it started up with the complete torrent.

*/

interface P2PMessage {

  //////////////////////////////////////////////////////////////////////////////
  // Commands
  
  // Generic Message Command
  // TODO may have to use a queue system
  async command void sendMessage(addr_t peer, message_t type, uint8_t* payload, size_t count); 

  // Similar to Ping just checks for a response
  async command void ping(hash_t* peerId);

  // A handshake is used to greet a new peer in the swam exchanging peer_t information
  // Who you are (PeerID) , what your after(torrent_t{bitvector,sha1}), what port you listen on(port_t), etc..
  async command void handshake(hash_t* peerId);

  // Ask the tracker for information about a torrent, tracker load, swarm status etc..
  async command void scrape(torrent_t* meta);

  // Acknowledge your presents in the p2p network and ask for peers
  async command void announce(void);

  // Send a piece to an address
  async command void sendPiece(hash_t* peerId, peice_t* piece);

  // Request a peice from an address; not sure when or if this mechanism will be used
  // Use a zero len piece to signal peice request
  async command void sendInterest(hash_t* peerId, hash_t* pieceId);

  //////////////////////////////////////////////////////////////////////////////
  // Events
  
  event void recvHandShake(hash_t* peerId, session_t* peerInfo);
  
  event void recvPiece(hash_t* peerId, piece_t* piece);

  event void recvInterest(hash_t* peerId, hash_t* pieceId);

  event void recvScrape(swarm_stats_t* swarmInfo);

  event void recvAnnounce(pool_t* peers);

}
