part of dartcoin.core;

class GetAddressMessage extends Message {
  
  GetAddressMessage([NetworkParameters params]) : super("getaddr", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  // required for serialization
  GetAddressMessage._newInstance() : super("getaddr", null);
  
  factory GetAddressMessage.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new GetAddressMessage._newInstance(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  @override
  void _deserializePayload() {}

  @override
  Uint8List _serializePayload() => new Uint8List(0);
}