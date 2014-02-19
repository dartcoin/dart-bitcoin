part of dartcoin.core;

class ScriptBuilder {
  
  final bool encoded;
  var _data;
  
  ScriptBuilder([bool this.encoded = true]) {
    if(encoded)
      _data = new List<int>();
    else
      _data = new List<ScriptChunk>(); // TODO change to linkedlist maybe
  }
  
  ScriptBuilder op(int opcode) {
    if(encoded)
      _data.add(opcode & 0xff);
    else
      _data.add(new ScriptChunk.fromOpCode(opcode & 0xff));
    return this;
  }
  
  ScriptBuilder data(Uint8List data) {
    if(encoded)
      _data.addAll(Script.encodeData(data));
    else
      _data.add(new ScriptChunk(false, data));
    return this;
  }
  
  ScriptBuilder smallNum(int num) {
    if(encoded)
      _data.add(Script.encodeToOpN(num));
    else
      _data.add(new ScriptChunk.fromOpCode(Script.encodeToOpN(num)));
    return this;
  }
  
  Script build() {
    if(encoded)
      return new Script(_data);
    else
      return new Script.fromChunks(_data);
  }
  
}