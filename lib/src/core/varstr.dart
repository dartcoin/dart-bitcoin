part of dartcoin.core;

class VarStr extends Object with BitcoinSerialization {
  
  String _content;
  
  VarStr(String content) {
    _content = content;
  }
  
  factory VarStr.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) =>
      new BitcoinSerialization.deserialize(new VarStr(""), bytes, length: length, lazy: lazy);
  
  String get content {
    _needInstance();
    return _content;
  }
  
  /**
   * The length of the string, not the length of the output bytes.
   */
  int get length => content.length;
  
  Uint8List _serialize() {
    List<int> result = new List<int>();
    List<int> contentBytes = new Utf8Codec().encode(content);
    result.addAll(new VarInt(contentBytes.length).serialize());
    result.addAll(contentBytes);
    return new Uint8List.fromList(result);
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    VarInt size = new VarInt.deserialize(bytes, lazy: false);
    offset += size.serializationLength;
    _content = new Utf8Codec().decode(bytes.sublist(offset, offset + size.value));
    offset += size.value;
    return offset;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int offset = 0;
    VarInt size = new VarInt.deserialize(bytes, lazy: false);
    offset += size.serializationLength;
    offset += size.value;
    return offset;
  }
  
}