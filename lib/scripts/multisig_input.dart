library bitcoin.scripts.input.multisig;

import "dart:typed_data";

import "package:cryptoutils/cryptoutils.dart";
import "package:pointycastle/api.dart";

import "package:bitcoin/core.dart";
import "package:bitcoin/script.dart";

class MultiSigInputScript extends Script {
  /**
   * Create a script that satisfies an [OP_CHECKMULTISIG] program.
   */
  factory MultiSigInputScript(List<TransactionSignature> signatures) {
    return new MultiSigInputScript.fromEncodedSignatures(
        new List.from(signatures.map((s) => s.bitcoinSerializedBytes(0))));
  }

  MultiSigInputScript.convert(Script script, [bool skipCheck = false]) : super(script.program) {
    if (!skipCheck && !matchesType(script))
      throw new ScriptException("Given script is not an instance of this script type.");
  }

  /**
   * Create a multisig script from signatures that have
   * already been encoded using the Bitcoin specification.
   * 
   * No checks on the encoding are performed.
   */
  factory MultiSigInputScript.fromEncodedSignatures(List<Uint8List> signatures) {
    if (signatures.length <= 0 || signatures.length > 16)
      throw new ScriptException("A minimum of 1 and a maximum of 16 signatures should be given.");
    ScriptBuilder builder = new ScriptBuilder()
      ..smallNum(
          0); // Work around a bug in CHECKMULTISIG that is now a required part of the protocol.
    signatures.forEach((s) => builder.data(s));
    return new MultiSigInputScript.convert(builder.build(), true);
  }

  /**
   * Create a multisig script from a list of keys and the [message] that they should sign.
   * 
   * Use [aesKeys] to specify the decryption keys for each key (if required). 
   * The [aesKeys] are mapped one-to-one with the [keys].
   */
  factory MultiSigInputScript.fromKeys(List<KeyPair> keys, Hash256 message,
      [List<KeyParameter> aesKeys]) {
    if (aesKeys == null) aesKeys = new List.filled(keys.length, null);
    List<TransactionSignature> signatures = new List<TransactionSignature>(keys.length);
    for (int i = 0; i < keys.length; i++) signatures[i] = keys[i].sign(message, aesKeys[i]);
    return new MultiSigInputScript(signatures);
  }

  List<TransactionSignature> get signatures =>
      chunks.sublist(0).map((c) => new TransactionSignature.deserialize(c.data));

  /**
   * 
   * 
   * It's not possible to be 100% sure that the data elements in the script are signatures.
   */
  static bool matchesType(Script script) {
    List<ScriptChunk> chunks = script.chunks;
    if (chunks.length > 17 || chunks.length < 2) return false;
    if (chunks[0].opCode != Script.encodeToOpN(0)) return false;
    for (int i = 1; i < chunks.length; i++) {
      if (chunks[i].isOpCode) return false;
    }
    return true;
  }
}
