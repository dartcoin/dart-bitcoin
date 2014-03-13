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
  
  Uint8List _serialize() {
    List<int> result;
    if(_value < 0xfd)
      result =  [_value];
    else if(_value <= 0xffff)
      result = [0xfd, 0, 0];
    else if(_value <= 0xffffffff)
      result = [0xfe, 0, 0, 0, 0];
    else
      result = [0xff, 0, 0, 0, 0, 0, 0, 0, 0];
    
    result.replaceRange(1, result.length, Utils.uintToBytesLE(_value, result.length + 1));
    // sublist is necessary due to doubtful implementation of replaceRange
    return new Uint8List.fromList(result.sublist(0, size));
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    if(bytes[0] == 0xfd) {
      _value = Utils.bytesToUintLE(bytes.sublist(1, 3));
      return 3;
    }
    else if(bytes[0] == 0xfe) {
      _value = Utils.bytesToUintLE(bytes.sublist(1, 5));
      return 5;
    }
    else if(bytes[0] == 0xff) {
      _value = Utils.bytesToUintLE(bytes.sublist(1, 9));
      return 9;
    }
    _value = bytes[0];
    return 1;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    if(bytes[0] == 0xfd) return 3;
    if(bytes[0] == 0xfe) return 5;
    if(bytes[0] == 0xff) return 9;
    return 1;
  }
  
  static int sizeOf(int value) {
    if(value < 0) throw new Exception("VarInt values should be at least 0!");
    if(value < 0xfd) return 1;
    if(value <= 0xffff) return 3;
    if(value <= 0xffffffff) return 5;
    return 9;
  }
  
}