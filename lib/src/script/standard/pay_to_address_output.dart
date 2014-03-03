part of dartcoin.core;

class PayToAddressOutputScript extends Script {
  
  static const int LENGTH = 25; // OP_DUP + OP_HASH160 + 0x14 + address (20) + OP_EQUALVERIFY + OP_CHECKSIG 
  
  /**
   * Create a new pay to address transaction output.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToAddressOutputScript(Address address, [bool encoded = true]) {
    return new ScriptBuilder(encoded)
      .op(ScriptOpCodes.OP_DUP)
      .op(ScriptOpCodes.OP_HASH160)
      .data(address.hash160)
      .op(ScriptOpCodes.OP_EQUALVERIFY)
      .op(ScriptOpCodes.OP_CHECKSIG)
      .build();
  }
  
  PayToAddressOutputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new ScriptException("Given script is not an instance of this script type.");
  }
  
  Address get address => new Address(bytes.getRange(3, 23));
  
  static bool matchesType(Script script) {
    return script.bytes.length == LENGTH &&
        script.bytes[0]  == ScriptOpCodes.OP_DUP &&
        script.bytes[1]  == ScriptOpCodes.OP_HASH160 &&
        script.bytes[2]  == 0x14 &&
        script.bytes[23] == ScriptOpCodes.OP_EQUALVERIFY &&
        script.bytes[24] == ScriptOpCodes.OP_CHECKSIG;
  }
}