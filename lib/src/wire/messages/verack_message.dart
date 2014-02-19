part of dartcoin.core;

class VerackMessage extends Message {
  
  VerackMessage() : super("verack");
  
  factory VerackMessage.deserialize(Uint8List bytes, {bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new VerackMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy);
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}