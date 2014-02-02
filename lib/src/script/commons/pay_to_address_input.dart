part of dartcoin.core;

class PayToAddressInputScript extends Script {
  
  factory PayToAddressInputScript(Uint8List signature, Uint8List pubKey) {
    List<ScriptChunk> chunks = new List();
    chunks.add(new ScriptChunk(false, signature));
    chunks.add(new ScriptChunk(false, pubKey));
    return new Script.fromChunks(chunks);
  }
  
  PayToAddressInputScript.convert(Script script) : super._fromBytes(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get signature {
    return chunks[0].data;
  }
  
  Uint8List get pubKey {
    return chunks[1].data;
  }
  
  Address get address {
    return new Address(pubKey);
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