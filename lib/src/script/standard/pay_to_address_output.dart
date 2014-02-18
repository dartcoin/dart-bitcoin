part of dartcoin.core;

class PayToAddressOutputScript extends Script {
  
  static const int LENGTH = 25; // OP_DUP + OP_HASH160 + 0x14 + address (20) + OP_EQUALVERIFY + OP_CHECKSIG 
  
  /**
   * Create a new pay to address transaction output.
   */
  factory PayToAddressOutputScript(Address address) {
    Uint8List script = new Uint8List(LENGTH);
    script[0]  = ScriptOpCodes.OP_DUP;
    script[1]  = ScriptOpCodes.OP_HASH160;
    script[2]  = 0x14;
    script.setRange(3, 23, address.hash160);
    script[23] = ScriptOpCodes.OP_EQUALVERIFY;
    script[24] = ScriptOpCodes.OP_CHECKSIG;
    return new Script(script);
  }
  
  /**
   * Creates exactly the same script, but built using chunks.
   * 
   * This is more efficient when the script is executed directly, 
   * but less efficient when it will be serialized after creation. 
   */
  factory PayToAddressOutputScript.withChunks(Address address) {
    List<ScriptChunk> chunks = new List()
      ..add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_DUP))
      ..add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_HASH160))
      ..add(new ScriptChunk(false, address.hash160))
      ..add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_EQUALVERIFY))
      ..add(new ScriptChunk.fromOpCode(ScriptOpCodes.OP_CHECKSIG));
    return new Script.fromChunks(chunks);
  }
  
  PayToAddressOutputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new Exception("Given script is not an instance of this script type.");
  }
  
  Address get address {
    return new Address(bytes.getRange(3, 23));
  }
  
  static bool matchesType(Script script) {
    return script.bytes.length == LENGTH &&
        script.bytes[0]  == ScriptOpCodes.OP_DUP &&
        script.bytes[1]  == ScriptOpCodes.OP_HASH160 &&
        script.bytes[2]  == 0x14 &&
        script.bytes[23] == ScriptOpCodes.OP_EQUALVERIFY &&
        script.bytes[24] == ScriptOpCodes.OP_CHECKSIG;
  }
}