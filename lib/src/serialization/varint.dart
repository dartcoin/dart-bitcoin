part of dartcoin.core;

class VarInt extends Object with BitcoinSerialization {
  
  int _value;
  
  VarInt(int this._value) {
    if(_value < 0) throw new Exception("VarInt values should be at least 0!");
  }
  
  factory VarInt.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) => 
      new BitcoinSerialization.deserialize(new VarInt(0), bytes, length: length, lazy: lazy, params: params);
  
  int get value {
    _needInstance();
    return _value;
  }
  
  /**
   * The size of the [VarInt] int bytes after serialization.
   */
  int get size {
    _needInstance();
    return sizeOf(this._value);
  }
  
  Uint8List _serialize() {
    List<int> result;
    if(_value < 0xfd)        result =  [_value];
    if(_value <= 0xffff)     result = [253, 0, 0];
    if(_value <= 0xffffffff) result = [254, 0, 0, 0, 0];
    if(result == null)       result = [255, 0, 0, 0, 0, 0, 0, 0, 0];
    
    result.replaceRange(1, result.length, Utils.uintToBytesLE(_value, result.length + 1));
    // sublist is necessary due to doubtful implementation of replaceRange
    return new Uint8List.fromList(result.sublist(0, size));
  }
  
  int _deserialize(Uint8List bytes) {
    if(bytes[0] == 253)
      _value = Utils.bytesToUintLE(bytes.sublist(1, 3));
    else if(bytes[0] == 254)
      _value = Utils.bytesToUintLE(bytes.sublist(1, 5));
    else if(bytes[0] == 255)
      _value = Utils.bytesToUintLE(bytes.sublist(1, 9));
    else 
      _value = bytes[0];
    return sizeOf(_value);
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    if(bytes[0] == 253) return 3;
    if(bytes[0] == 254) return 5;
    if(bytes[0] == 255) return 9;
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