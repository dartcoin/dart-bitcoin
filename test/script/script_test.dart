library dartcoin.test.script.script_test;

import "dart:collection";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:bignum/bignum.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:test/test.dart";

import "package:dartcoin/core.dart";
import "package:dartcoin/script.dart";
import "package:dartcoin/scripts/common.dart";
import "package:dartcoin/src/utils.dart" as utils;
import "../test_config.dart";

//TODO basic matchesType tests for all supported standard types

// From tx 05e04c26c12fe408a3c1b71aa7996403f6acad1045252b1c62e055496f4d2cb1 on the testnet.

final String sigProg =
    "47304402202b4da291cc39faf8433911988f9f49fc5c995812ca2f94db61468839c228c3e90220628bff3ff32ec95825092fa051cba28558a981fcf59ce184b14f2e215e69106701410414b38f4be3bb9fa0f4f32b74af07152b2f2f630bc02122a491137b6c523e46f18a0d5034418966f93dfc37cc3739ef7b2007213a302b7fba161557f4ad644a1c";

final String pubkeyProg = "76a91433e81a941e64cda12c6a299ed322ddbdd03f8d0e88ac";

final NetworkParameters params = NetworkParameters.TEST_NET;

void main() {
  group("script.ScriptTest", () {
    test("toString", () {
      Script s = new ScriptBuilder()
          .op(ScriptOpCodes.OP_DUP)
          .data(new Uint8List.fromList([0xff, 0xff]))
          .op(Script.encodeToOpN(4))
          .op(ScriptOpCodes.OP_EQUALVERIFY)
          .build(false);
      expect(s.toString(), equals("DUP [ffff] 4 EQUALVERIFY"));
    });

    test("fromString", () {
      Script s = new Script.fromString("DUP [ffff] 4 EQUALVERIFY");
      expect(s.chunks.length, equals(4));
      expect(s.chunks[0], equals(new ScriptChunk.opCodeChunk(ScriptOpCodes.OP_DUP)));
      expect(s.chunks[1], equals(new ScriptChunk.dataChunk(new Uint8List.fromList([0xff, 0xff]))));
      expect(s.chunks[2], equals(new ScriptChunk.opCodeChunk(Script.encodeToOpN(4))));
      expect(s.chunks[3], equals(new ScriptChunk.opCodeChunk(ScriptOpCodes.OP_EQUALVERIFY)));
    });

    test("scriptSig", () {
      Uint8List sigProgBytes = CryptoUtils.hexToBytes(sigProg);
      Script script = new Script(sigProgBytes);
      expect(PayToPubKeyHashInputScript.matchesType(script), isTrue);
      // Test we can extract the from address.
      PayToPubKeyHashInputScript converted = new PayToPubKeyHashInputScript.convert(script);
      Address a = converted.getAddress(params);
      expect(a.toString(), equals("mkFQohBpy2HDXrCwyMrYL5RtfrmeiuuPY2"));
    });

    test("scriptPubKey", () {
      // Check we can extract the to address
      Uint8List pubkeyBytes = CryptoUtils.hexToBytes(pubkeyProg);
      Script pubkey = new Script(pubkeyBytes);
      expect(pubkey.toString(),
          equals("DUP HASH160 [33e81a941e64cda12c6a299ed322ddbdd03f8d0e] EQUALVERIFY CHECKSIG"));
      expect(PayToPubKeyHashOutputScript.matchesType(pubkey), isTrue);
      PayToPubKeyHashOutputScript converted = new PayToPubKeyHashOutputScript.convert(pubkey);
      Address toAddr = converted.getAddress(params);
      expect(toAddr.toString(), equals("mkFQohBpy2HDXrCwyMrYL5RtfrmeiuuPY2"));
    });

    test("multiSig", () {
      List<KeyPair> keys = [new KeyPair.generate(), new KeyPair.generate(), new KeyPair.generate()];

      expect(() => new MultiSigOutputScript(2, keys), returnsNormally);
      expect(() => new MultiSigOutputScript(3, keys), returnsNormally);
      expect(
          MultiSigOutputScript
              .matchesType(new PayToPubKeyHashOutputScript.withAddress(keys[0].getAddress(params))),
          isFalse);

      // Fail if we ask for more signatures than keys.
      expect(() => new MultiSigOutputScript(4, keys), throwsA(new isInstanceOf<ScriptException>()));
      expect(() => new MultiSigOutputScript(0, keys), throwsA(new isInstanceOf<ScriptException>()));
      // Actual execution is tested by the data driven tests.
    });

    test("p2sh", () {
      Address p2shAddress = new Address("35b9vsyH1KoFT5a5KtrKusaCcPLkiSo1tU");
      expect(
          PayToScriptHashOutputScript
              .matchesType(new PayToScriptHashOutputScript.withAddress(p2shAddress)),
          isTrue);
    });

    test("ip", () {
      Uint8List bytes = CryptoUtils.hexToBytes(
          "41043e96222332ea7848323c08116dddafbfa917b8e37f0bdf63841628267148588a09a43540942d58d49717ad3fabfe14978cf4f0a8b84d2435dad16e9aa4d7f935ac");
      Script s = new Script(bytes);
      expect(PayToPubKeyOutputScript.matchesType(s), isTrue);
    });

    group("bitcoinj-vectors", () {
      test("valid-scripts", () {
        File f = new File.fromUri(new Uri.file("$RESOURCES/script_valid.json"));
        List<List> vectors = JSON.decode(f.readAsStringSync());

        for (List instance in vectors) {
          if (instance.length < 2) continue;
          Script scriptSig = parseScriptString(instance[0]);
          Script scriptPubKey = parseScriptString(instance[1]);
          scriptSig.correctlySpends(new Transaction(), 0, scriptPubKey, true);
          expect(() => scriptSig.correctlySpends(new Transaction(), 0, scriptPubKey, true),
              returnsNormally,
              reason: JSON.encode(instance));
        }
      });

      test("invalid-scripts", () {
        File f = new File.fromUri(new Uri.file("$RESOURCES/script_invalid.json"));
        List<List> vectors = JSON.decode(f.readAsStringSync());

        for (List instance in vectors) {
          if (instance.length < 2) continue;
          Script scriptSig = parseScriptString(instance[0]);
          Script scriptPubKey = parseScriptString(instance[1]);

          expect(() => scriptSig.correctlySpends(new Transaction(), 0, scriptPubKey, true),
              throwsA(new isInstanceOf<ScriptException>()),
              reason: JSON.encode(instance));
        }
      });

      test("valid-tx", () {
        File f = new File.fromUri(new Uri.file("$RESOURCES/tx_valid.json"));
        List<List> vectors = JSON.decode(f.readAsStringSync());

        instances:
        for (List instance in vectors) {
          if (instance.length < 2) continue;
          Map<TransactionOutPoint, Script> scriptPubKeys = new Map<TransactionOutPoint, Script>();
          for (List input in instance[0]) {
            String hash = input[0];
            int index = input[1];
            String script = input[2];
            Hash256 sha256Hash = new Hash256(hash);
            Script s = parseScriptString(script);
            // tmp skip scripts with CHECKSIG or MULTISIG
            for (ScriptChunk sc in s.chunks) {
              if (sc.opCode == ScriptOpCodes.OP_CHECKMULTISIG ||
                  sc.opCode == ScriptOpCodes.OP_CHECKMULTISIGVERIFY ||
                  sc.opCode == ScriptOpCodes.OP_CHECKSIG ||
                  sc.opCode == ScriptOpCodes.OP_CHECKSIGVERIFY) {
                continue instances;
              }
            }
            scriptPubKeys[new TransactionOutPoint(index: index, txid: sha256Hash)] = s;
          }

          Uint8List bytes = CryptoUtils.hexToBytes(instance[1]);
          Transaction transaction = new Transaction.fromBitcoinSerialization(bytes, 0);
          bool enforceP2SH = instance[2];

          expect(() => transaction.verify(), returnsNormally, reason: JSON.encode(instance));

          for (int i = 0; i < transaction.inputs.length; i++) {
            TransactionInput input = transaction.inputs[i];
            if (input.outpoint.index == 0xffffffff) input.outpoint.index = -1;
            expect(scriptPubKeys.containsKey(input.outpoint), isTrue);

            // tmp skip scripts with CHECKSIG or MULTISIG
            for (ScriptChunk sc in input.scriptSig.chunks) {
              if (sc.opCode == ScriptOpCodes.OP_CHECKMULTISIG ||
                  sc.opCode == ScriptOpCodes.OP_CHECKMULTISIGVERIFY ||
                  sc.opCode == ScriptOpCodes.OP_CHECKSIG ||
                  sc.opCode == ScriptOpCodes.OP_CHECKSIGVERIFY) {
                continue instances;
              }
            }

            expect(
                () => input.scriptSig
                    .correctlySpends(transaction, i, scriptPubKeys[input.outpoint], enforceP2SH),
                returnsNormally,
                reason:
                    "Erroring scriptSig: ${input.scriptSig} for script ${scriptPubKeys[input.outpoint]}");
          }
        }
      });

      test("invalid-tx", () {
        File f = new File.fromUri(new Uri.file("$RESOURCES/tx_invalid.json"));
        List<List> vectors = JSON.decode(f.readAsStringSync());

        instances:
        for (List instance in vectors) {
          if (instance.length < 2) continue;
          Map<TransactionOutPoint, Script> scriptPubKeys = new Map<TransactionOutPoint, Script>();
          for (List input in instance[0]) {
            String hash = input[0];
            int index = input[1];
            String script = input[2];
            Hash256 sha256Hash = new Hash256(hash);
            scriptPubKeys[new TransactionOutPoint(index: index, txid: sha256Hash)] =
                parseScriptString(script);
          }

          Uint8List bytes = CryptoUtils.hexToBytes(instance[1]);
          Transaction transaction = new Transaction.fromBitcoinSerialization(bytes, 0);
          bool enforceP2SH = instance[2];
          // we use a bool instead of multiple tests, because only one test has to fail
          bool valid = true;

          try {
            transaction.verify();
          } on VerificationException {
            valid = false;
          }

          // check for double spent manually
          Set<TransactionOutPoint> outpoints = new HashSet<TransactionOutPoint>();
          for (TransactionInput ti in transaction.inputs) {
            if (outpoints.contains(ti.outpoint)) valid = false;
            if (!valid) break;
            outpoints.add(ti.outpoint);
          }

          for (int i = 0; i < transaction.inputs.length && valid; i++) {
            TransactionInput input = transaction.inputs[i];
            if (input.outpoint.index == 0xffffffff) input.outpoint.index = -1;
            expect(scriptPubKeys.containsKey(input.outpoint), isTrue);

            try {
              input.scriptSig
                  .correctlySpends(transaction, i, scriptPubKeys[input.outpoint], enforceP2SH);
            } on VerificationException {
              valid = false;
            }
          }

          expect(valid, isFalse, reason: JSON.encode(instance));
        }
      });
    });
  });
}

Script parseScriptString(String string) {
  List<String> words = string.split(new RegExp("[ \\t\\n]"));

  List<int> out = new List<int>();

  for (String w in words) {
    if (w == "") continue;
    if (new RegExp("^-?[0-9]*\$").hasMatch(w)) {
      // Number
      int val = int.parse(w);
      if (val >= -1 && val <= 16)
        out.add(Script.encodeToOpN(val));
      else
        out.addAll(
            Script.encodeData(utils.reverseBytes(utils.encodeMPI(new BigInteger(val), false))));
    } else if (new RegExp("^0x[0-9a-fA-F]*\$").hasMatch(w)) {
      // Raw hex data, inserted NOT pushed onto stack:
      out.addAll(CryptoUtils.hexToBytes(w.substring(2)));
    } else if (w.length >= 2 && w.startsWith("'") && w.endsWith("'")) {
      // Single-quoted string, pushed as data. NOTE: this is poor-man's
      // parsing, spaces/tabs/newlines in single-quoted strings won't work.
      out.addAll(Script.encodeData(utils.stringToUTF8(w.substring(1, w.length - 1))));
      //Script.writeBytes(out, w.substring(1, w.length() - 1).getBytes(Charset.forName("UTF-8")));
    } else if (ScriptOpCodes.getOpCode(w) != ScriptOpCodes.OP_INVALIDOPCODE) {
      // opcode, e.g. OP_ADD or OP_1:
      out.add(ScriptOpCodes.getOpCode(w));
    } else if (w.startsWith("OP_") &&
        ScriptOpCodes.getOpCode(w.substring(3)) != ScriptOpCodes.OP_INVALIDOPCODE) {
      // opcode, e.g. OP_ADD or OP_1:
      out.add(ScriptOpCodes.getOpCode(w.substring(3)));
    } else {
      throw new Exception("Invalid Data: $w");
    }
  }

  return new Script(new Uint8List.fromList(out));
}
