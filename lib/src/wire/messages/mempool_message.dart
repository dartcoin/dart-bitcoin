part of dartcoin.core;

class MemPoolMessage extends Message {
  
  MemPoolMessage() : super("mempool");

  factory MemPoolMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new MemPoolMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadDeserialization(bytes, this);
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}