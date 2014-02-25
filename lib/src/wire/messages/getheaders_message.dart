part of dartcoin.core;

class GetHeadersMessage extends RequestMessage {
  
  GetHeadersMessage(List<Sha256Hash> locators, [Sha256Hash stop]) : super("getheaders", locators, stop);

  factory GetHeadersMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new GetHeadersMessage(null, null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
}