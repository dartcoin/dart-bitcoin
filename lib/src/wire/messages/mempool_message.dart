part of dartcoin.core;

class MemPoolMessage extends Message {
  
  MemPoolMessage([NetworkParameters params]) : super("mempool", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  // required for serialization
  MemPoolMessage._newInstance() : super("mempool", null);

  factory MemPoolMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new MemPoolMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  @override
  void _deserializePayload() {}

  @override
  void _serializePayload(ByteSink sink) {}
}