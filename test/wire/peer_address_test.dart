library bitcoin.test.wire.peer_address;

import "package:test/test.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:bitcoin/wire.dart";

void main() {
  group("wire.PeerAddress", () {
    test("peerAddressRoundtrip", () {
      // copied verbatim from https://en.bitcoin.it/wiki/Protocol_specification#Network_address
      String fromSpec = "010000000000000000000000000000000000ffff0a000001208d";
      PeerAddress pa =
          new PeerAddress.fromBitcoinSerialization(CryptoUtils.hexToBytes(fromSpec), 0);
      String reserialized = CryptoUtils.bytesToHex(pa.bitcoinSerializedBytes(0));
      expect(reserialized, equals(fromSpec));
    });

    test("serialize", () {
      PeerAddress pa = new PeerAddress("127.0.0.1", port: 8333);
      expect(CryptoUtils.bytesToHex(pa.bitcoinSerializedBytes(0)),
          equals("000000000000000000000000000000000000ffff7f000001208d"));
    });
  });
}
