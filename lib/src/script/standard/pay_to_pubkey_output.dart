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
    if(!(pubKey is Uint8List)) throw new ArgumentError("The public key can be either of type Uint8List or KeyPair.");
    return new ScriptBuilder(encoded)
      .data(pubKey)
      .op(ScriptOpCodes.OP_CHECKSIG)
      .build();
  }
  
  PayToPubKeyOutputScript.convert(Script script, [bool skipCheck = false]) : super(script.bytes) {
    if(!skipCheck && !matchesType(script)) 
      throw new ScriptException("Given script is not an instance of this script type.");
  }
  
  KeyPair get pubKey => new KeyPair.public(chunks[0].bytes);
  
  Address getAddress([NetworkParameters params]) => new KeyPair.public(pubKey).getAddress(params);
  
  static bool matchesType(Script script) {
    return script.chunks.length == 2 && 
        script.chunks[0].bytes.length > 1 &&
        script.chunks[1].equalsOpCode(ScriptOpCodes.OP_CHECKSIG);
  }
}