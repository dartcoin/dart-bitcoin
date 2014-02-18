part of dartcoin.core;

class PayToPubKeyInput extends Script {
  
  factory PayToPubKeyInput(Uint8List signature) {
    List<ScriptChunk> chunks = new List();
    chunks.add(new ScriptChunk(false, signature));
    return new Script.fromChunks(chunks);
  }
  
  PayToPubKeyInput.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get signature {
    return chunks[0].data;
  }
  
  /**
   * Script must contain only one chunk, the signature data chunk.
   */
  static bool matchesType(Script script) {
    return script.chunks.length == 1 && 
        script.chunks[0].data.length > 1;
  }
}