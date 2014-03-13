part of dartcoin.core;

class FilterClearMessage extends Message {
  
  FilterClearMessage([NetworkParameters params]) : super("filterclear", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  // required for serialization
  FilterClearMessage._newInstance() : super("filterclear", null);

  factory FilterClearMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new FilterClearMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) => 0;
  
  Uint8List _serialize_payload() => new Uint8List(0);
}