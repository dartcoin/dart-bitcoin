part of dartcoin.core;

class ScriptBuilder {
  
  final bool encoded;
  // this parameter is either List<int> or List<ScriptChunk>
  var _data;
  
  /**
   * Initialize a new [ScriptBuilder].
   * 
   * Use [encoded] to specify if the output script should be generated from a
   * serialization or from a list of [ScriptChunk]s.
   * For serializing and transmitting the script, set [encoded] to true, while
   * for executing the script, set [encoded] to false.
   */
  ScriptBuilder([bool this.encoded = true]) {
    if(encoded)
      _data = new List<int>();
    else
      _data = new List<ScriptChunk>();
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
      return new Script(new Uint8List.fromList(_data));
    else
      return new Script(new List.from(_data));
  }
  
}