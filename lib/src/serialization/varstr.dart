part of dartcoin.core;

class VarStr extends Object with BitcoinSerialization {
  
  String _content;
  
  VarStr(String content) {
    _content = content;
  }
  
  VarStr._newInstance();
  
  factory VarStr.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params}) =>
      new BitcoinSerialization.deserialize(new VarStr._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params);
  
  String get content {
    _needInstance();
    return _content;
  }
  
  /**
   * The size of the [VarStr] in bytes after serialization.
   */
  int get size {
    int byteLength = new Utf8Codec().encode(content).length;
    return VarInt.sizeOf(byteLength) + byteLength;
  }
  
  /**
   * The length of the string, not the length of the output bytes.
   */
  int get length => content.length;
  
  @override
  String toString() => content;
  
  @override
  bool operator ==(VarStr other) {
    if(other is! VarStr) return false;
    if(identical(this, other)) return true;
    _needInstance();
    other._needInstance();
    return _content == other._content;
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _content.hashCode;
  }

  @override
  void _serialize(ByteSink sink) {
    _writeByteArray(sink, new Utf8Encoder().convert(_content));
  }

  @override
  void _deserialize() {
    _content = new Utf8Decoder().convert(_readByteArray());
  }

  @override
  void _deserializeLazy() {
    int size = _readVarInt();
    _serializationCursor += size;
  }
  
}