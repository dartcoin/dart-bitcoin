part of dartcoin.core;

class PayToScriptHashOutputScript extends Script {
  
  /**
   * Create a new P2SH output script.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToScriptHashOutputScript(Uint8List scriptHash, [bool encoded = true]) {
    if(scriptHash == null || scriptHash.length != 20)
      throw new ScriptException("The script hash must be of size 20!");
    return new ScriptBuilder(encoded)
      .op(ScriptOpCodes.OP_HASH160)
      .data(scriptHash)
      .op(ScriptOpCodes.OP_EQUAL)
      .build();
  }
  
  PayToScriptHashOutputScript.convert(Script script) : super(script.bytes) {
    if(!matchesType(script)) throw new ScriptException("Given script is not an instance of this script type.");
  }
  
  Uint8List get scriptHash => new Uint8List.fromList(bytes.getRange(2, 22));


  /**
   * <p>Whether or not this is a scriptPubKey representing a pay-to-script-hash output. In such outputs, the logic that
   * controls reclamation is not actually in the output at all. Instead there's just a hash, and it's up to the
   * spending input to provide a program matching that hash. This rule is "soft enforced" by the network as it does
   * not exist in Satoshis original implementation. It means blocks containing P2SH transactions that don't match
   * correctly are considered valid, but won't be mined upon, so they'll be rapidly re-orgd out of the chain. This
   * logic is defined by <a href="https://en.bitcoin.it/wiki/BIP_0016">BIP 16</a>.</p>
   *
   * <p>bitcoinj does not support creation of P2SH transactions today. The goal of P2SH is to allow short addresses
   * even for complex scripts (eg, multi-sig outputs) so they are convenient to work with in things like QRcodes or
   * with copy/paste, and also to minimize the size of the unspent output set (which improves performance of the
   * Bitcoin system).</p>
   */
  static bool matchesType(Script script) {
    return script.bytes.length == 23 && 
        script.bytes[0] == ScriptOpCodes.OP_HASH160 &&
        script.bytes[1] == 0x14 &&
        script.bytes[22] == ScriptOpCodes.OP_EQUAL;
  }
  
  
}