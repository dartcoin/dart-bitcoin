part of dartcoin.core;

class GetAddrMessage extends Message {
  
  GetAddrMessage() : super("getaddr");
  
  factory GetAddrMessage.deserialize(Uint8List bytes, {bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new GetAddrMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy);
  
  void _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    _serializationLength = offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}