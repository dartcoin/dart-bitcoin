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
    _chunks.add(new ScriptChunk.opCode(opcode & 0xff));
    return this;
  }
  
  ScriptBuilder data(Uint8List data) {
    _chunks.add(new ScriptChunk.data(data));
    return this;
  }
  
  ScriptBuilder smallNum(int num) {
    _chunks.add(new ScriptChunk.opCode(Script.encodeToOpN(num)));
    return this;
  }
  
  Script build([bool encoded = false]) {
    return new Script(encoded ? buildBytes() : new List.from(_chunks));
  }

  Uint8List buildBytes() {
    Buffer buffer = new Buffer();
    for(ScriptChunk chunk in _chunks) {
      buffer.add(chunk.bytes);
    }
    return buffer.asBytes();
  }
  
}