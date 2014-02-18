part of dartcoin.core;

class PayToAddressInputScript extends Script {
  
  factory PayToAddressInputScript(Uint8List signature, Uint8List pubKey) {
    List<int> script = new List<int>()
      ..addAll(Script.encodeData(signature))
      ..addAll(Script.encodeData(pubKey));
    return new Script(new Uint8List.fromList(script));
  }
  
  /**
   * Creates exactly the same script, but built using chunks.
   * 
   * This is more efficient when the script is executed directly, 
   * but less efficient when it will be serialized after creation. 
   */
  factory PayToAddressInputScript.withChunks(Uint8List signature, Uint8List pubKey) {
    List<ScriptChunk> chunks = new List<ScriptChunk>()
      ..add(new ScriptChunk(false, signature))
      ..add(new ScriptChunk(false, pubKey));
    return new Script.fromChunks(chunks);
  }
  
  PayToAddressInputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get signature {
    return chunks[0].data;
  }
  
  Uint8List get pubKey {
    return chunks[1].data;
  }
  
  Address getAddress([NetworkParameters params]) {
    return new KeyPair(pubKey).toAddress(params);
  }
  
  /**
   * Script must contain two chunks, each of which are data chunks.
   */
  static bool matchesType(Script script) {
    return script.chunks.length == 2 && 
        script.chunks[0].data.length > 1 && 
        script.chunks[1].data.length > 1;
  }
}