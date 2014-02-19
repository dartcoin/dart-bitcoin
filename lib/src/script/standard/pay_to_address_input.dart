part of dartcoin.core;

class PayToAddressInputScript extends Script {
  
  /**
   * 
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToAddressInputScript(Uint8List signature, Uint8List pubKey, [bool encoded = true]) {
    return new ScriptBuilder(encoded)
      .data(signature)
      .data(pubKey)
      .build();
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