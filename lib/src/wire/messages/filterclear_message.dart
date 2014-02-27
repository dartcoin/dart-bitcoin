part of dartcoin.core;

class FilterClearMessage extends Message {
  
  FilterClearMessage() : super("filterclear");

  factory FilterClearMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new FilterClearMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes) => 0;
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}