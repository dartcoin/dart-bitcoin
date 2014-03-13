part of dartcoin.core;

class VerackMessage extends Message {
  
  VerackMessage([NetworkParameters params]) : super("verack", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  factory VerackMessage.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VerackMessage(), bytes, length: Message.HEADER_LENGTH, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) => 0;
  
  Uint8List _serialize_payload() => new Uint8List(0);
}