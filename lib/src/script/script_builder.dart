part of dartcoin.script;

class ScriptBuilder {
  List<ScriptChunk> _chunks;
  
  /**
   * Initialize a new [ScriptBuilder].
   */
  ScriptBuilder() {
    _chunks = new List<ScriptChunk>();
  }
  
  ScriptBuilder op(int opcode) {
    _chunks.add(new ScriptChunk.opCodeChunk(opcode));
    return this;
  }
  
  ScriptBuilder data(Uint8List data) {
    _chunks.add(new ScriptChunk.dataChunk(data));
    return this;
  }
  
  ScriptBuilder smallNum(int num) {
    _chunks.add(new ScriptChunk.opCodeChunk(Script.encodeToOpN(num)));
    return this;
  }
  
  Script build([bool encoded = false]) {
    return new Script(encoded ? buildBytes() : new List.from(_chunks));
  }

  Uint8List buildBytes() {
    var buffer = new bytes.Buffer();
    for(ScriptChunk chunk in _chunks) {
      buffer.add(chunk.data);
    }
    return buffer.asBytes();
  }
  
}