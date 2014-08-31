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

  @override
  void _deserializePayload() {
    _data = _readByteArray();
  }

  @override
  Uint8List _serializePayload() {
    return new Uint8List.fromList(
        new List<int>()
        ..addAll(new VarInt(_data.length).serialize())
        ..addAll(_data));
  }
}