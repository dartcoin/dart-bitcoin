part of dartcoin.core;

class PayToScriptHash extends Script {
  
  factory PayToScriptHash(Uint8List scriptHash) {
    if(scriptHash == null || scriptHash.length != 20)
      throw new Exception("The script hash must be of size 20!");
    Uint8List script = new Uint8List(23);
    script[0] = ScriptOpCodes.OP_HASH160;
    script[1] = 0x14;
    script.setRange(2, 22, scriptHash);
    script[22] = ScriptOpCodes.OP_EQUAL;
    return new Script(script);
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