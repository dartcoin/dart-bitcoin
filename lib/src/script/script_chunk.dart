part of dartcoin.core;

class ScriptChunk {
  bool _isOpCode;
  Uint8List _data;
  int _startLocationInProgram;
  
  ScriptChunk(bool isOpCode, Uint8List data, [int startLocationInProgram]) {
    if(isOpCode && data.length != 1) throw new ArgumentError("OpCode data must be of length 1.");
    if(data.length > Script.MAX_SCRIPT_ELEMENT_SIZE) throw new ArgumentError("ScriptChunk data exceeds max data size.");
    _isOpCode = isOpCode;
    _data = new Uint8List.fromList(data);
    _startLocationInProgram = startLocationInProgram;
  }
  
  ScriptChunk.fromOpCode(int opCode) {
    _isOpCode = true;
    _data = new Uint8List.fromList([0xff & opCode]);
  }
  
  bool get isOpCode => _isOpCode;
  
  Uint8List get data => new Uint8List.fromList(_data);
  
  int get startLocationInProgram => _startLocationInProgram;
  
  String toString() {
    if(_isOpCode)
      return ScriptOpCodes.getOpCodeName(data[0]);
    else
      return "[" + Utils.bytesToHex(data) + "]";
  }
  
  bool equalsOpCode(int opCode) => _isOpCode && _data.length == 1 && _data[0] == opCode;
  
  Uint8List serialize() => _isOpCode ? new Uint8List.fromList(_data) : Script.encodeData(data);
}