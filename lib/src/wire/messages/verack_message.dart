part of dartcoin.core;

class VerackMessage extends Message {
  
  VerackMessage() : super("verack");
  
  factory VerackMessage.deserialize(Uint8List bytes, {bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VerackMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}