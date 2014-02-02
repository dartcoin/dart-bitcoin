part of dartcoin.core;

class PayToPubKeyOutputScript extends Script {
  
  factory PayToPubKeyOutputScript(Uint8List pubKey) { //TODO maybe replace by pubkey object
    List<ScriptChunk> chunks = new List();
    chunks.add(new ScriptChunk(false, pubKey));
    chunks.add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_CHECKSIG));
    return new Script.fromChunks(chunks);
  }
  
  PayToPubKeyOutputScript.convert(Script script) : super._fromBytes(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get pubKey {
    return chunks[0].data;
  }
  
  Address get address {
    return new Address(Utils.sha256hash160(pubKey));
  }
  
  static bool matchesType(Script script) {
    return script.chunks.length == 2 && 
        script.chunks[0].data.length > 1 && 
        script.chunks[1].equalsOpCode(ScriptOpCodes.OP_CHECKSIG);
  }
}