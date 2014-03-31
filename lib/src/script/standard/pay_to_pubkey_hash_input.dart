part of dartcoin.core;

class PayToPubKeyHashInputScript extends Script {
  
  /**
   * 
   * 
   * The value for [signature] can be either a [TransactionSignature] or a [Uint8List]. 
   * [pubKey] can be either of type [KeyPair] or [Uint8List].
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyHashInputScript(dynamic signature, dynamic pubKey, [bool encoded = true]) {
    if(signature is TransactionSignature) 
      signature = signature.encodeToDER();
    if(pubKey is KeyPair)
      pubKey = pubKey.publicKey;
    if(!(signature is Uint8List && pubKey is Uint8List))
      throw new ArgumentError("Unsupported input types. Read documentation.");
    return new ScriptBuilder(encoded)
      .data(signature)
      .data(pubKey)
      .build();
  }
  
  PayToPubKeyHashInputScript.convert(Script script, [bool skipCheck = false]) : super(script.bytes) {
    if(!skipCheck && !matchesType(script)) 
      throw new ScriptException("Given script is not an instance of this script type.");
  }
  
  TransactionSignature get signature => new TransactionSignature.deserialize(chunks[0].data, length: chunks[0].data.length, requireCanonical: false);
  
  KeyPair get pubKey => new KeyPair.public(chunks[1].data);
  
  Address getAddress([NetworkParameters params]) => pubKey.getAddress(params);
  
  /**
   * Script must contain two chunks, each of which are data chunks.
   */
  static bool matchesType(Script script) {
    return script.chunks.length == 2 && 
        script.chunks[0].data.length > 1 && 
        script.chunks[1].data.length > 1;
  }
}