part of dartcoin.core;

class VerackMessage extends Message {
  
  VerackMessage([NetworkParameters params]) : super("verack", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }

  // required for serialization
  VerackMessage._newInstance() : super("verack", null);
  
  factory VerackMessage.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VerackMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  @override
  void _deserializePayload() {}

  @override
  void _serializePayload(ByteSink sink) {}
}