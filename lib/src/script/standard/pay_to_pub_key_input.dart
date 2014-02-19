part of dartcoin.core;

class PayToPubKeyInput extends Script {
  
  /**
   * 
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyInput(Uint8List signature, [bool encoded = true]) {
    return new ScriptBuilder(encoded)
      .data(signature)
      .build();
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