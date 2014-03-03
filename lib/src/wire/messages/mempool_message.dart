part of dartcoin.core;

class MemPoolMessage extends Message {
  
  MemPoolMessage() : super("mempool") {
    _serializationLength = Message.HEADER_LENGTH;
  }

  factory MemPoolMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new MemPoolMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes) => 0;
  
  Uint8List _serialize_payload() => new Uint8List(0);
}