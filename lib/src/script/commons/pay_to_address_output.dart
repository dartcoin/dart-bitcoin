part of dartcoin.core;

class PayToAddressOutputScript extends Script {
  
  factory PayToAddressOutputScript(Address address) {
    List<ScriptChunk> chunks = new List();
    chunks.add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_DUP));
    chunks.add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_HASH160));
    chunks.add(new ScriptChunk(false, address.hash160));
    chunks.add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_EQUALVERIFY));
    chunks.add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_CHECKSIG));
    return new Script.fromChunks(chunks);
  }
  
  PayToAddressOutputScript.convert(Script script) : super._fromBytes(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Address get address {
    return new Address(chunks[2].data);
  }
  
  static bool matchesType(Script script) {
    return script.chunks.length == 5 && 
        script.chunks[0].equalsOpCode(ScriptOpCodes.OP_DUP) && 
        script.chunks[1].equalsOpCode(ScriptOpCodes.OP_HASH160) && 
        script.chunks[2].data.length == Address.LENGTH && 
        script.chunks[3].equalsOpCode(ScriptOpCodes.OP_EQUALVERIFY) && 
        script.chunks[4].equalsOpCode(ScriptOpCodes.OP_CHECKSIG);
  }
}