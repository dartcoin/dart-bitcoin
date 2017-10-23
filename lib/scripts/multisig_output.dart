library bitcoin.scripts.output.multisig;

import "package:bitcoin/core.dart";
import "package:bitcoin/script.dart";

class MultiSigOutputScript extends Script {
  /**
   * Create a new multi-signature output script that requires at least <threshold> of the given keys to sign using
   * OP_CHECKMULTISIG.
   * 
   * Standard multisig outputs have max 3 keys, but it is possible to add up to 16 keys.
   * 
   * If [encoded] is set to false, the script will be built using chunks. This improves
   * performance when the script is intended for execution.
   */
  factory MultiSigOutputScript(int threshold, List<KeyPair> pubkeys) {
    if (threshold <= 0 || threshold > pubkeys.length)
      throw new ScriptException("Invalid threshold value.");
    if (pubkeys.length > 16) throw new ScriptException("Maximum 16 public keys.");

    ScriptBuilder builder = new ScriptBuilder().smallNum(threshold);
    pubkeys.forEach((pk) => builder.data(pk.publicKey));
    builder.smallNum(pubkeys.length).op(ScriptOpCodes.OP_CHECKMULTISIG);
    return new MultiSigOutputScript.convert(builder.build(), true);
  }

  MultiSigOutputScript.convert(Script script, [bool skipCheck = false]) : super(script.program) {
    if (!skipCheck && !matchesType(script))
      throw new ScriptException("Given script is not an instance of this script type.");
  }

  int get threshold => Script.decodeFromOpN(chunks[0].data[0]);

  List<KeyPair> get pubKeys {
    List<KeyPair> keys = new List();
    for (int i = 0; i < (chunks.length - 3); i++) {
      keys.add(new KeyPair.public(chunks[i + 1].data));
    }
    return keys;
  }

  static bool matchesType(Script script) {
    List<ScriptChunk> chunks = script.chunks;
    // script length must be 3 + #pubkeys with max 16 pubkeys
    if (chunks.length < 4 || chunks.length > 19) return false;
    // second chunks must be OP_N code with threshold, value from 0 to 16
    try {
      if (Script.decodeFromOpN(chunks[0].opCode) < 0 ||
          Script.decodeFromOpN(chunks[0].data[0]) > 16) return false;
    } on ScriptException {
      // invalid OP_N
      return false;
    }
    // intermediate chunks must be data chunks. these are the pubkeys
    for (int i = 0; i < (chunks.length - 3); i++) {
      if (chunks[i + 1].data.length <= 1) return false;
    }
    // one but last chunk must be OP_N code with #pubkeys, must be #chunks - 1
    if (Script.decodeFromOpN(chunks[chunks.length - 2].data[0]) != chunks.length - 3) return false;
    // last chunk must be OP_MULTISIG opcode
    return chunks[chunks.length - 1].opCode == ScriptOpCodes.OP_CHECKMULTISIG;
  }
}
