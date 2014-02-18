part of dartcoin.core;

class ScriptChunk {
  bool _isOpCode;
  Uint8List _data;
  int _startLocationInProgram;
  
  ScriptChunk(bool isOpCode, Uint8List data, [int startLocationInProgram]) {
    if(isOpCode && data.length != 1) throw new Exception("OpCode data must be of length 1.");
    if(data.length > Script.MAX_SCRIPT_ELEMENT_SIZE) throw new Exception("ScriptChunk data exceeds max data size.");
    _isOpCode = isOpCode;
    _data = data;
    _startLocationInProgram = startLocationInProgram;
  }
  
  ScriptChunk.fromOpCode(int opCode) {
    _isOpCode = true;
    _data = new Uint8List.fromList([0xff & opCode]);
  }
  
  bool get isOpCode {
    return _isOpCode;
  }
  
  Uint8List get data {
    return _data;
  }
  
  int get startLocationInProgram {
    return _startLocationInProgram;
  }
  
  String toString() {
    if(isOpCode) {
      return ScriptOpCodes.getOpCodeName(data[0]);
    }
    else {
      return "[" + Utils.bytesToHex(data) + "]";
    }
  }
  
  bool equalsOpCode(int opCode) {
    return isOpCode && data.length == 1 && _data[0] == opCode;
  }
  
  Uint8List serialize() {
    if(isOpCode) {
      return data;
    }
    else {
      return Script.encodeData(data);
    }
  }
}