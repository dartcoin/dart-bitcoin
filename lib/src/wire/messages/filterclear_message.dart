part of dartcoin.core;

class FilterClearMessage extends Message {
  
  FilterClearMessage([NetworkParameters params]) : super("filterclear", params) {
    _serializationLength = Message.HEADER_LENGTH;
  }
  
  // required for serialization
  FilterClearMessage._newInstance() : super("filterclear", null);

  factory FilterClearMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new FilterClearMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  @override
  void _deserializePayload() {}

  @override
  Uint8List _serializePayload() => new Uint8List(0);
}