part of dartcoin.core;

class PayToPubKeyOutputScript extends Script {
  
  /**
   * Create a new output for a given public key.
   * 
   * The public key can be either of type Uint8List or KeyPair.
   */
  factory PayToPubKeyOutputScript(dynamic pubKey) {
    if(pubKey is KeyPair) pubKey = pubKey.publicKey;
    if(!(pubKey is Uint8List)) throw new Exception("The public key can be either of type Uint8List or KeyPair.");
    List<ScriptChunk> chunks = new List()
      ..add(new ScriptChunk(false, pubKey))
      ..add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_CHECKSIG));
    return new Script.fromChunks(chunks);
  }
  
  PayToPubKeyOutputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get pubKey {
    return chunks[0].data;
  }
  
  Address getAddress([NetworkParameters params]) {
    return new KeyPair(pubKey).toAddress(params);
  }
  
  static bool matchesType(Script script) {
    return script.chunks.length == 2 && 
        script.chunks[0].data.length > 1 && 
        script.chunks[1].equalsOpCode(ScriptOpCodes.OP_CHECKSIG);
  }
}