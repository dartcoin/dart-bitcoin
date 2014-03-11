library dartcoin.test.core.keypair;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

String testPrivKey = "18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725";
String testPubKey = "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
String testAddress = "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM";

void _testAddress(String publicKey, String address) {
  var bytes = Utils.hexToBytes("0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6");
  KeyPair kp = new KeyPair(bytes);
  expect(kp.toAddress(), equals(new Address(address)));
}

void _testPrivToPub(String publicKey, String privateKey) {
  var privBytes = Utils.hexToBytes(privateKey);
  KeyPair kp = new KeyPair(null, privBytes, false);
  var pub = Utils.bytesToHex(kp.publicKey);
  expect(pub, equalsIgnoringCase(publicKey));
  expect(kp.privateKeyBytes, equals(privBytes));
}

void _testClear(String privateKey) {
  KeyPair kp = new KeyPair(null, Utils.hexToBytes(privateKey));
  kp.clearPrivateKey();
  expect(kp.privateKey, isNull);
  expect(kp.privateKeyBytes, isNull);
}

void _testEqualsAndHashCode(String private, String public) {
  KeyPair kp1 = new KeyPair(null, Utils.hexToBytes(private));
  KeyPair kp2 = new KeyPair(null, Utils.hexToBytes(private));
  KeyPair kp3 = new KeyPair(Utils.hexToBytes(public));
  KeyPair kp4 = new KeyPair(Utils.hexToBytes(public));
  expect(kp1 == kp2, isTrue);
  expect(kp1 == kp1, isTrue);
  expect(kp3 == kp4, isTrue);
  expect(kp1 == kp3, isFalse);
  expect(kp1.hashCode == kp2.hashCode, isTrue);
  expect(kp3.hashCode == kp4.hashCode, isTrue);
}

void main() {
  test("keypair_address1", () => _testAddress(testPubKey, testAddress));
  test("keypair_privpub1", () => _testPrivToPub(testPubKey, testPrivKey));
  test("keypair_clear", () => _testClear(testPrivKey));
  test("keypair_equals_hashcode", () => _testEqualsAndHashCode(testPrivKey, testPubKey));
}







