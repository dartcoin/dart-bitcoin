part of dartcoin.core;

class FilterAddMessage extends Message {
  
  static const int MAX_DATA_SIZE = 520;
  
  Uint8List _data;
  
  FilterAddMessage(Uint8List data, [NetworkParameters params]) : super("filteradd", params) {
    if(data.length > MAX_DATA_SIZE)
      throw new ArgumentError("Data attribute is too large.");
    _data = new Uint8List.fromList(data);
    _serializationLength = Message.HEADER_LENGTH + VarInt.sizeOf(_data.length) + _data.length;
  }
  
  // required for serialization
  FilterAddMessage._newInstance() : super("filteradd", null);
  
  factory FilterAddMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
    new BitcoinSerialization.deserialize(
        new FilterAddMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Uint8List get data {
    _needInstance();
    return new Uint8List.fromList(_data);
  }

  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    VarInt dataSize = new VarInt.deserialize(bytes, lazy: false);
    offset += dataSize.size;
    _data = bytes.sublist(offset, offset + dataSize.value);
    offset += dataSize.value;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return new Uint8List.fromList(
        new List<int>()
        ..addAll(new VarInt(_data.length).serialize())
        ..addAll(_data));
  }
}