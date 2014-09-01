part of dartcoin.core;

class GetBlocksMessage extends RequestMessage {
  
  GetBlocksMessage(List<Hash256> locators, [Hash256 stop, NetworkParameters params]) : super("getblocks", locators, stop, params);
  
  // required for serialization
  GetBlocksMessage._newInstance() : super._newInstance("getblocks");
  
  factory GetBlocksMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new GetBlocksMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
}