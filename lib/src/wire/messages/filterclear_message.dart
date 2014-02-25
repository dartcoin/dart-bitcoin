part of dartcoin.core;

class FilterClearMessage extends Message {
  
  FilterClearMessage() : super("filterclear");

  factory FilterClearMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new FilterClearMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}