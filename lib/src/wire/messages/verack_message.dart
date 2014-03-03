part of dartcoin.core;

class VerackMessage extends Message {
  
  VerackMessage() : super("verack") {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  factory VerackMessage.deserialize(Uint8List bytes, {bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VerackMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes) => 0;
  
  Uint8List _serialize_payload() => new Uint8List(0);
}