part of dartcoin;

class VarInt extends Object with ByteRepresentation {
  
  int _value;
  
  VarInt(int this._value) {
    if(_value < 0) throw new Exception("VarInt values should be at elast 0!");
  }
  
  factory VarInt.decode(Uint8List bytes) => _fromBytes(bytes);
  
  int get value {
    _needInstance();
    return _value;
  }
  
  int get size {
    _needInstance();
    return sizeOf(this._value);
  }
  
  void _decode(Uint8List bytes) {
    if(bytes.length < 1 || bytes.length > 9)
      throw new Exception("VarInt are at least 1 and at most 9 bytes.");
    if(bytes[0] == 253) {
      _value = Utils.bytesToIntLE(bytes.sublist(1, 3));
      return;
    }
    if(bytes[0] == 254) {
      _value = Utils.bytesToIntLE(bytes.sublist(1, 5));
      return;
    }
    if(bytes[0] == 255) {
      _value = Utils.bytesToIntLE(bytes.sublist(1, 9));
      return;
    }
    _value = bytes[0];
  }
  
  Uint8List _encode() {
    List<int> result;
    if(_value < 0xfd)        result =  [_value];
    if(_value <= 0xffff)     result = [253, 0, 0];
    if(_value <= 0xffffffff) result = [254, 0, 0, 0, 0];
    if(result == null)      result = [255, 0, 0, 0, 0, 0, 0, 0, 0];
    
    result.replaceRange(1, result.length, Utils.intToBytesLE(_value));
    // sublist is necessary due to doubtful implementation of replaceRange
    return new Uint8List.fromList(result.sublist(0, size));
  }
  
  static int sizeOf(int value) {
    if(value < 0) throw new Exception("VarInt values should be at least 0!");
    
    if(value < 0xfd) return 1;
    if(value <= 0xffff) return 3;
    if(value <= 0xffffffff) return 5;
    return 9;
  }
  
}