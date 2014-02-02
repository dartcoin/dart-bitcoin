part of dartcoin.core;

class Script {
  
  static final int MAX_SCRIPT_ELEMENT_SIZE = 520; //bytes
  
  List<ScriptChunk> _chunks;
  Uint8List _bytes;
  
  Script(Uint8List bytes) {
    _bytes = bytes;
    _chunks = null;
  }
  
  Script._fromBytes(Uint8List bytes) {
    _bytes = bytes;
    _chunks = null;
  }
  
  Script.fromChunks(List<ScriptChunk> chunks) {
    _chunks = chunks;
    _bytes = null;
  }
  
  Uint8List get bytes {
    if(_bytes == null) {
      _bytes = encode();
    }
    return _bytes;
  }
  
  List<ScriptChunk> get chunks {
    if(_chunks == null) {
      parse();
    }
    return _chunks;
  }
  
  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.writeAll(chunks, " ");
    return buf.toString();
  }
  
  void parse() {
    List<ScriptChunk> chunks = new List();
    List<int> revbuf = _bytes.reversed;
    while(revbuf.length > 0) {
      int opcode = revbuf.removeLast();
      
      int dataToRead = -1;
      if(opcode >= 0 && opcode < ScriptOpCodes.OP_PUSHDATA1) {
        dataToRead = opcode;
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA1) {
        if(revbuf.length < 1) throw new Exception("Unexpected end of script");
        dataToRead = revbuf.removeLast();
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA2) {
        if(revbuf.length < 2) throw new Exception("Unexpected end of script");
        dataToRead = revbuf.removeLast() | (revbuf.removeLast() << 8);
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA4) {
        if(revbuf.length < 2) throw new Exception("Unexpected end of script");
        dataToRead = revbuf.removeLast() | (revbuf.removeLast() << 8) | (revbuf.removeLast() << 16) | (revbuf.removeLast() << 24);
      }
      
      if(dataToRead < 0) {
        chunks.add(new ScriptChunk(true, new Uint8List.fromList([opcode])));
      }
      else {
        if (dataToRead > revbuf.length)
          throw new Exception("Push of data element that is larger than remaining data");
        chunks.add(new ScriptChunk(false, new Uint8List.fromList(_reverseLast(dataToRead, revbuf))));
      }
    }
    _chunks = chunks;
  }
  
  /**
   * Takes the last n elements from reverseBuffer and returns them in opposite order. 
   * So that the last element from reverseBuffer is the first from the result.
   */
  List<int> _reverseLast(int n, List<int> reverseBuffer) {
    List<int> result = new List();
    for(int i ; i < n ; i++) {
      result.add(reverseBuffer.removeLast());
    }
    return result;
  }
  
  Uint8List encode() {
    if(_bytes != null) return _bytes;
    List<int> bytes = new List();
    for(ScriptChunk chunk in chunks) {
      bytes.addAll(chunk.data);
    }
    return new Uint8List.fromList(bytes);
  }
  
  static int decodeFromOpN(int opcode) {
    if(! (opcode == ScriptOpCodes.OP_0 || opcode == ScriptOpCodes.OP_1NEGATE || 
        (opcode >= ScriptOpCodes.OP_1 && opcode <= ScriptOpCodes.OP_16)) ) {
      throw new Exception("Method should be called on an OP_N opcode.");
    }
    if (opcode == ScriptOpCodes.OP_0)
      return 0;
    else if (opcode == ScriptOpCodes.OP_1NEGATE)
      return -1;
    else
      return opcode + 1 - ScriptOpCodes.OP_1;
  }
  
  static int encodeToOpN(int value) {
    if(! (value >= -1 && value <= 16) ) {
      throw new Exception("Can only encode for values -1 <= value <= 16.");
    }
    if (value == 0)
      return ScriptOpCodes.OP_0;
    else if (value == -1)
      return ScriptOpCodes.OP_1NEGATE;
    else
      return value - 1 + ScriptOpCodes.OP_1;
  }
  
}






