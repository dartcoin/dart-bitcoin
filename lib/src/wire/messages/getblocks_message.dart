part of dartcoin.core;

class GetBlocksMessage extends RequestMessage {
  
  GetBlocksMessage(List<Sha256Hash> locators, [Sha256Hash stop]) : super("getblocks", locators, stop);
  
  factory GetBlocksMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new GetBlocksMessage(null, null), bytes, length: length, lazy: lazy);
  
}