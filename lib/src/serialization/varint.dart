part of dartcoin.core;


class VarInt extends Object with BitcoinSerialization {
  
  int _value;
  
  VarInt(int value) {
    if(value < 0) 
      throw new ArgumentError("VarInt values should be at least 0!");
    _value = value;
    _serializationLength = sizeOf(value);
  }
  
  // required for serialization
  VarInt._newInstance();
  
  factory VarInt.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params}) => 
      new BitcoinSerialization.deserialize(new VarInt._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params);
  
  int get value {
    _needInstance();
    return _value;
  }
  
  /**
   * The size of the [VarInt] int bytes after serialization.
   */
  int get size {
    _needInstance();
    return sizeOf(_value);
  }
  
  @override
  String toString() => "$value";
  
  @override
  bool operator ==(VarInt other) {
    if(other is! VarInt) return false;
    if(identical (this, other)) return true;
    _needInstance();
    other._needInstance();
    return _value == other._value;
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _value.hashCode;
  }

  @override
  void _serialize(ByteSink sink) {
    if(_value < 0xfd) {
      sink.add(_value);
    } else if(_value <= 0xffff) {
      sink.add(0xfd);
      _writeUintLE(sink, _value, 2);
    } else if(_value <= 0xffffffff) {
      sink.add(0xfe);
      _writeUintLE(sink, _value, 4);
    } else {
      sink.add(0xff);
      _writeUintLE(sink, _value, 8);
    }
  }

  @override
  void _deserialize() {
    int firstByte = _readUintLE(1);
    if(firstByte == 0xfd) {
      _value = _readUintLE(2);
      return;
    }
    if(firstByte == 0xfe) {
      _value = _readUintLE(4);
      return;
    }
    if(firstByte == 0xff) {
      _value = _readUintLE(8);
      return;
    }
    _value = firstByte;
  }

  @override
  void _deserializeLazy() {
    int firstByte = _readUintLE(1);
    int size = 0;
    if(firstByte == 0xfd) size = 2;
    else if(firstByte == 0xfe) size = 4;
    else if(firstByte == 0xff) size = 8;
    _serializationCursor += size;
  }
  
  static int sizeOf(int value) {
    if(value < 0) throw new Exception("VarInt values should be at least 0!");
    if(value < 0xfd) return 1;
    if(value <= 0xffff) return 3;
    if(value <= 0xffffffff) return 5;
    return 9;
  }
  
}