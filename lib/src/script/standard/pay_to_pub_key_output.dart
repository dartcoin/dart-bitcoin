part of dartcoin.core;

class PayToPubKeyOutputScript extends Script {
  
  /**
   * Create a new output for a given public key.
   * 
   * The public key can be either of type Uint8List or KeyPair.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyOutputScript(dynamic pubKey, [bool encoded = true]) {
    if(pubKey is KeyPair) pubKey = pubKey.publicKey;
    if(!(pubKey is Uint8List)) throw new Exception("The public key can be either of type Uint8List or KeyPair.");
    return new ScriptBuilder(encoded)
      .data(pubKey)
      .op(ScriptOpCodes.OP_CHECKSIG)
      .build();
  }
  
  PayToPubKeyOutputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  KeyPair get pubKey {
    return new KeyPair(chunks[0].data);
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