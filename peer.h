#ifndef __PEER_H__
#define __PEER_H__

#include "hash.h"
#include "bitvector.h"
#include "addr.h"

#define MAX_PEER_CONNECTIONS 4

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  hash_t peerId;
  addr_t addr;

  bitvector_t interests;
  bitvector_t completed;

} peer_t;

static peer_t pxPeerTable[MAX_PEER_CONNECTIONS];

peer_t* pxPeerTableWalk(hash_t peerId){

  uint16_t index = MAX_PEER_CONNECTIONS;

  while(index--)
    if(pxPeerTable[index].peerId == peerId) break; 

  if( index < 0 )
    return (peer_t*) 0x00;

  return pxPeerTable + index;
}

void vPeerTableAdd(peer_t* peer){}

#endif
