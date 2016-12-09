library dartcoin.scripts.output.pay_to_pubkey_hash;

import "dart:typed_data";

import "package:cryptoutils/cryptoutils.dart";

import "package:dartcoin/core.dart";
import "package:dartcoin/script.dart";

import "package:dartcoin/scripts/pay_to_address_output.dart";

class PayToPubKeyHashOutputScript extends PayToAddressOutputScript {
  
  static const int LENGTH = 25; // OP_DUP + OP_HASH160 + 0x14 + address (20) + OP_EQUALVERIFY + OP_CHECKSIG 
  
  /**
   * Create a new pay to address transaction output.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyHashOutputScript(Hash160 pubkeyHash, [bool encoded = true]) {
    return new PayToPubKeyHashOutputScript.convert(new ScriptBuilder()
      .op(ScriptOpCodes.OP_DUP)
      .op(ScriptOpCodes.OP_HASH160)
      .data(pubkeyHash.asBytes())
      .op(ScriptOpCodes.OP_EQUALVERIFY)
      .op(ScriptOpCodes.OP_CHECKSIG)
      .build(encoded), true);
  }
  
  /**
   * Auxiliary constructor for paying to a regular address.
   */
  factory PayToPubKeyHashOutputScript.withAddress(Address address, [bool encoded = true]) =>
    new PayToPubKeyHashOutputScript(address.hash160, encoded);
  
  PayToPubKeyHashOutputScript.convert(Script script, [bool skipCheck = false])
      : super.fromBytesUnchecked(script.bytes) {
    if(!skipCheck && !matchesType(script)) 
      throw new ScriptException("Given script is not an instance of this script type.");
  }
  
  Uint8List get pubkeyHash => new Uint8List.fromList(bytes.sublist(3,  23));

  Address getAddress([NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      new Address.fromHash160(pubkeyHash, params.addressHeader);
  
  static bool matchesType(Script script) {
    return script.bytes.length == LENGTH &&
        script.bytes[0]  == ScriptOpCodes.OP_DUP &&
        script.bytes[1]  == ScriptOpCodes.OP_HASH160 &&
        script.bytes[2]  == 0x14 &&
        script.bytes[23] == ScriptOpCodes.OP_EQUALVERIFY &&
        script.bytes[24] == ScriptOpCodes.OP_CHECKSIG;
  }
}