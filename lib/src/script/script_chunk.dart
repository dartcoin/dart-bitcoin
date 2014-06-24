part of dartcoin.core;

class ScriptChunk {
  bool _isOpCode;
  Uint8List _data;
  int _startLocationInProgram;
  
  ScriptChunk(bool isOpCode, Uint8List data, [int startLocationInProgram]) {
    if(isOpCode && data.length != 1) throw new ArgumentError("OpCode data must be of length 1.");
    //if(data.length > Script.MAX_SCRIPT_ELEMENT_SIZE) throw new ArgumentError("ScriptChunk data exceeds max data size.");
    _isOpCode = isOpCode;
    _data = new Uint8List.fromList(data);
    _startLocationInProgram = startLocationInProgram;
  }
  
  ScriptChunk.opCode(int opCode) {
    _isOpCode = true;
    _data = new Uint8List.fromList([0xff & opCode]);
  }

  ScriptChunk.data(Uint8List data) {
    _isOpCode = false;
    _data = new Uint8List.fromList(data);
  }
  
  bool get isOpCode => _isOpCode;
  
  Uint8List get bytes => new Uint8List.fromList(_data);
  
  int get startLocationInProgram => _startLocationInProgram;
  
  @override
  String toString() {
    if(_isOpCode)
      return ScriptOpCodes.getOpCodeName(bytes[0]);
    else
      return "[" + Utils.bytesToHex(bytes) + "]";
  }
  
  bool equalsOpCode(int opCode) => _isOpCode && _data[0] == opCode;
  
  Uint8List serialize() => _isOpCode ? new Uint8List.fromList(_data) : Script.encodeData(bytes);
  
  @override
  bool operator ==(ScriptChunk other) {
    if(other is! ScriptChunk) return false;
    return _isOpCode == other._isOpCode && Utils.equalLists(_data, other._data);
  }
  
  @override
  int get hashCode => (_isOpCode ? 0xffff : 0) ^ Utils.listHashCode(_data);
}