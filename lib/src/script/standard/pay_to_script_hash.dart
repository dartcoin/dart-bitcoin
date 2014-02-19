part of dartcoin.core;

class PayToScriptHash extends Script {
  
  /**
   * Create a new P2SH output script.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToScriptHash(Uint8List scriptHash, [bool encoded = true]) {
    if(scriptHash == null || scriptHash.length != 20)
      throw new Exception("The script hash must be of size 20!");
    return new ScriptBuilder(encoded)
      .op(ScriptOpCodes.OP_HASH160)
      .data(scriptHash)
      .op(ScriptOpCodes.OP_EQUAL)
      .build();
  }
  
  PayToScriptHash.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Uint8List get scriptHash {
    return bytes.getRange(2, 22);
  }
  
  static bool matchesType(Script script) {
    return script.bytes.length == 23 && 
        script.bytes[0] == ScriptOpCodes.OP_HASH160 &&
        script.bytes[1] == 0x14 &&
        script.bytes[22] == ScriptOpCodes.OP_EQUAL;
  }
  
  
}