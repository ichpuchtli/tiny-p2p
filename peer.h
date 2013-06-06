#ifndef __PEER_H__
#define __PEER_H__

#include "hash.h"
#include "bitvector.h"
#include "addr.h"

#define PEER_TABLE_SIZE 4

typedef struct {

  // Pack header structure here for when these structures are sent
  p2p_header_t header;

  hash_t peerId; // = hash struct sockaddr_in6* addr
  addr_t addr;

  //bitvector_t interests;
  //bitvector_t completed;

} peer_t;


peer_t pxPeerTable[PEER_TABLE_SIZE];

/*static */ uint8_t ucPeerCount = 0;

peer_t* pxPeerTableWalk(hash_t peerId){

  uint16_t index = PEER_TABLE_SIZE;

  while(index--)
    if(pxPeerTable[index].peerId == peerId) break; 

  if( index < 0 )
    return (peer_t*) 0x00;

  return (peer_t*)(pxPeerTable + index);
}

void vPeerTableAdd(peer_t* peer){

  if(ucPeerCount < PEER_TABLE_SIZE){
    memcpy((void*) (pxPeerTable + ucPeerCount), (void*) peer, sizeof(peer_t));
    ucPeerCount++;
  }

}

#endif
