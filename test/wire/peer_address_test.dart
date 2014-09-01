library dartcoin.test.wire.peer_address;

import "package:unittest/unittest.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:dartcoin/core/core.dart";

void _testPeerAddressRoundtrip() {
  // copied verbatim from https://en.bitcoin.it/wiki/Protocol_specification#Network_address
  String fromSpec = "010000000000000000000000000000000000ffff0a000001208d";
  PeerAddress pa = new PeerAddress.deserialize(CryptoUtils.hexToBytes(fromSpec), lazy: false, params: NetworkParameters.MAIN_NET, protocolVersion: 0);
  String reserialized = CryptoUtils.bytesToHex(pa.serialize());
  expect(reserialized, equals(fromSpec));
}

void _testBitcoinSerialize() {
  PeerAddress pa = new PeerAddress("127.0.0.1", port: 8333, protocolVersion: 0);
  expect(CryptoUtils.bytesToHex(pa.serialize()), equals("000000000000000000000000000000000000ffff7f000001208d"));
}

    
void main() {
  group("wire.PeerAddress", () {
    test("peerAddressRoundtrip", () => _testPeerAddressRoundtrip());
    test("serialize", () => _testBitcoinSerialize());
  });
}