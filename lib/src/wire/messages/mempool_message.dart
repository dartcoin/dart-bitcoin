part of dartcoin.core;

class MemPoolMessage extends Message {
  
  MemPoolMessage() : super("mempool");

  factory MemPoolMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new MemPoolMessage(), bytes, length: length, lazy: lazy);
  
  void _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    _serializationLength = offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}