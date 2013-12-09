part of dartcoin.wire;

class GetBlocksMessage extends RequestMessage {
  
  GetBlocksMessage(List<Sha256Hash> locators, [Sha256Hash stop]) : super("getblocks", locators, stop);
  
}