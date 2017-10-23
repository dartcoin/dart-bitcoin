library dartcoin.test.wire.alert_message;

import "dart:typed_data";

import "package:bytes/bytes.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:test/test.dart";

import "package:dartcoin/core.dart";
import "package:dartcoin/wire.dart";

Uint8List _TEST_KEY_PRIV =
    CryptoUtils.hexToBytes("6421e091445ade4b24658e96aa60959ce800d8ea9e7bd8613335aa65ba8d840b");

void main() {
  group("wire.messages.AlertMessage", () {
    test("deserialize", () {
      // A CAlert taken from the reference implementation.
      Uint8List payload = CryptoUtils.hexToBytes(
          "5c010000004544eb4e000000004192ec4e00000000eb030000e9030000000000000048ee00000088130000002f43416c6572742073797374656d20746573743a2020202020202020207665722e302e352e3120617661696c61626c6500473045022100ec799908c008b272d5e5cd5a824abaaac53d210cc1fa517d8e22a701ecdb9e7002206fa1e7e7c251d5ba0d7c1fe428fc1870662f2927531d1cad8d4581b45bc4f8a7");

      AlertMessage alert = new AlertMessage.empty();
      alert.bitcoinDeserialize(new Reader(payload), 0);

      expect(alert.relayUntil.millisecondsSinceEpoch ~/ 1000, equals(1324041285));
      expect(alert.expiration.millisecondsSinceEpoch ~/ 1000, equals(1324126785));
      expect(alert.id, equals(1003));
      expect(alert.cancel, equals(1001));
      expect(alert.minVer, equals(0));
      expect(alert.maxVer, equals(61000));
      expect(alert.priority, equals(5000));
      expect(alert.statusBar, equals("CAlert system test:         ver.0.5.1 available"));
      expect(alert.isSignatureValid(new KeyPair.private(_TEST_KEY_PRIV).publicKey), isTrue);
    });
  });
}
