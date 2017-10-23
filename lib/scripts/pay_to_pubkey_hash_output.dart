library dartcoin.scripts.output.pay_to_pubkey_hash;

import "dart:typed_data";

import "package:cryptoutils/cryptoutils.dart";

import "package:dartcoin/core.dart";
import "package:dartcoin/script.dart";

class PayToPubKeyHashOutputScript extends Script {
  static const int LENGTH =
      25; // OP_DUP + OP_HASH160 + 0x14 + address (20) + OP_EQUALVERIFY + OP_CHECKSIG

  /**
   * Create a new pay to address transaction output.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyHashOutputScript(Hash160 pubkeyHash) {
    return new PayToPubKeyHashOutputScript.convert(
        new ScriptBuilder()
            .op(ScriptOpCodes.OP_DUP)
            .op(ScriptOpCodes.OP_HASH160)
            .data(pubkeyHash.asBytes())
            .op(ScriptOpCodes.OP_EQUALVERIFY)
            .op(ScriptOpCodes.OP_CHECKSIG)
            .build(),
        true);
  }

  /**
   * Auxiliary constructor for paying to a regular address.
   */
  factory PayToPubKeyHashOutputScript.withAddress(Address address) =>
      new PayToPubKeyHashOutputScript(address.hash160);

  PayToPubKeyHashOutputScript.convert(Script script, [bool skipCheck = false])
      : super(script.program) {
    if (!skipCheck && !matchesType(script))
      throw new ScriptException("Given script is not an instance of this script type.");
  }

  Uint8List get pubkeyHash => new Uint8List.fromList(program.sublist(3, 23));

  Address getAddress([NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      new Address.fromHash160(pubkeyHash, params.addressHeader);

  static bool matchesType(Script script) {
    return script.program.length == LENGTH &&
        script.program[0] == ScriptOpCodes.OP_DUP &&
        script.program[1] == ScriptOpCodes.OP_HASH160 &&
        script.program[2] == 0x14 &&
        script.program[23] == ScriptOpCodes.OP_EQUALVERIFY &&
        script.program[24] == ScriptOpCodes.OP_CHECKSIG;
  }
}
