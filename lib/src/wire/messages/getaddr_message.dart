part of dartcoin.core;

class GetAddrMessage extends Message {
  
  GetAddrMessage() : super("getaddr");
  
  factory GetAddrMessage.deserialize(Uint8List bytes, {bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new GetAddrMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes) => 0;
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}