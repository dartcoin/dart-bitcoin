library bitcoin.scripts.output.pay_to_pubkey;

import "dart:typed_data";

import "package:bitcoin/core.dart";
import "package:bitcoin/script.dart";

class PayToPubKeyOutputScript extends Script {
  /**
   * Create a new output for a given public key.
   * 
   * The public key can be either of type Uint8List or KeyPair.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory PayToPubKeyOutputScript(dynamic pubKey) {
    if (pubKey is KeyPair) pubKey = pubKey.publicKey;
    if (!(pubKey is Uint8List))
      throw new ArgumentError("The public key can be either of type Uint8List or KeyPair.");
    return new PayToPubKeyOutputScript.convert(
        new ScriptBuilder().data(pubKey).op(ScriptOpCodes.OP_CHECKSIG).build(), true);
  }

  PayToPubKeyOutputScript.convert(Script script, [bool skipCheck = false]) : super(script.program) {
    if (!skipCheck && !matchesType(script))
      throw new ScriptException("Given script is not an instance of this script type.");
  }

  KeyPair get pubKey => new KeyPair.public(chunks[0].data);

  Address getAddress([NetworkParameters params]) => pubKey.getAddress(params);

  static bool matchesType(Script script) {
    return script.chunks.length == 2 &&
        script.chunks[0].data.length > 1 &&
        script.chunks[1].opCode == ScriptOpCodes.OP_CHECKSIG;
  }
}
