part of dartcoin.core;

class GetHeadersMessage extends RequestMessage {
  
  GetHeadersMessage(List<Hash256> locators, [Hash256 stop, NetworkParameters params]) : super("getheaders", locators, stop, params);
  
  // required for serialization
  GetHeadersMessage._newInstance() : super._newInstance("getheaders");

  factory GetHeadersMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new GetHeadersMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
}