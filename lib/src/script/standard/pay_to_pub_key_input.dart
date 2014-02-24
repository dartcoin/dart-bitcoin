part of dartcoin.core;

class PayToPubKeyInput extends Script {
  
  /**
   * 
   * 
   * The value for [signature] can be either a [TransactionSignature] or a [Uint8List]. 
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyInput(dynamic signature, [bool encoded = true]) {
    if(signature is TransactionSignature)
      signature = signature.encodeToDER();
    if(!(signature is Uint8List))
      throw new Exception("The value for signature can be either a TransactionSignature or a Uint8List.");
    return new ScriptBuilder(encoded)
      .data(signature)
      .build();
  }
  
  PayToPubKeyInput.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  TransactionSignature get signature {
    return new TransactionSignature.deserialize(chunks[0].data);
  }
  
  /**
   * Script must contain only one chunk, the signature data chunk.
   */
  static bool matchesType(Script script) {
    return script.chunks.length == 1 && 
        script.chunks[0].data.length > 1;
  }
}