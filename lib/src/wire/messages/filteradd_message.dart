part of dartcoin.core;

class FilterAddMessage extends Message {
  
  static const int MAX_DATA_SIZE = 520;
  
  Uint8List _data;
  
  FilterAddMessage(Uint8List data) : super("filteradd") {
    if(data.length > MAX_DATA_SIZE)
      throw new Exception("Data attribute is too large.");
    _data = data;
  }
  
  Uint8List get data {
    _needInstance();
    return _data;
  }
  
  factory FilterAddMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new FilterAddMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);

  int _deserializePayload(Uint8List bytes) {
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