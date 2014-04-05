library dartcoin.test.core.keypair;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "package:crypto/crypto.dart";
import "package:bignum/bignum.dart";
import "dart:math";
import "dart:typed_data";
import "dart:io";
import "dart:async";
import "package:json/json.dart" as json;
import "package:cipher/cipher.dart";

String _testPrivKey1 = "18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725";
String _testPubKey1 = "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
String _testAddress1 = "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM";

void _testAddress(String publicKey, String address) {
  var bytes = Utils.hexToBytes("0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6");
  KeyPair kp = new KeyPair.public(bytes);
  expect(kp.getAddress(), equals(new Address(address)));
}

void _testPrivToPub(String publicKey, String privateKey) {
  var privBytes = Utils.hexToBytes(privateKey);
  KeyPair kp = new KeyPair.private(privBytes, compressed: false);
  var pub = Utils.bytesToHex(kp.publicKey);
  expect(pub, equalsIgnoringCase(publicKey));
  expect(kp.privateKeyBytes, equals(privBytes));
}

void _testClear(String privateKey) {
  KeyPair kp = new KeyPair.private(Utils.hexToBytes(privateKey));
  kp.clearPrivateKey();
  expect(kp.privateKey, isNull);
  expect(kp.privateKeyBytes, isNull);
}

void _testEqualsAndHashCode(String private, String public) {
  KeyPair kp1 = new KeyPair.private(Utils.hexToBytes(private));
  KeyPair kp2 = new KeyPair.private(Utils.hexToBytes(private));
  KeyPair kp3 = new KeyPair.public(Utils.hexToBytes(public));
  KeyPair kp4 = new KeyPair.public(Utils.hexToBytes(public));
  expect(kp1 == kp2, isTrue);
  expect(kp1 == kp1, isTrue);
  expect(kp3 == kp4, isTrue);
  expect(kp1 == kp3, isFalse);
  expect(kp1.hashCode == kp2.hashCode, isTrue);
  expect(kp3.hashCode == kp4.hashCode, isTrue);
}



KeyCrypter _keyCrypter;

String _PASSWORD1      = "my hovercraft has eels";
String _WRONG_PASSWORD = "it is a snowy day today";

void _setUp() {
  _keyCrypter = new KeyCrypterScrypt(iterations: 8);
}


void _sValue() {
  // Check that we never generate an S value that is larger than half the curve order. This avoids a malleability
  // issue that can allow someone to change a transaction [hash] without invalidating the signature.
  final int ITERATIONS = 10;
  final KeyPair key = new KeyPair();
  for (int i = 0; i < ITERATIONS; i++) {
    final Sha256Hash hash = new Sha256Hash.digest(new Uint8List.fromList([i]));
    ECDSASignature signature = key.sign(hash);
    var a = (signature.s / KeyPair.HALF_CURVE_ORDER).toString();
    expect(signature.s <= KeyPair.HALF_CURVE_ORDER, isTrue);
  }
}


void _testSignatures() {
  // Test that we can construct an KeyPair from a private key (deriving the public from the private), then signing
  // a message with it.
  BigInteger privkey = new BigInteger.fromBytes(1, Utils.hexToBytes("180cb41c7c600be951b5d3d0a7334acc7506173875834f7a6c4c786a28fcbb19"));
  KeyPair key = new KeyPair.private(privkey);
  ECDSASignature output = key.sign(Sha256Hash.ZERO_HASH);
  expect(key.verify(Sha256Hash.ZERO_HASH.bytes, output), isTrue);

  // Test interop with a signature from elsewhere.
  Uint8List sig = Utils.hexToBytes("3046022100dffbc26774fc841bbe1c1362fd643609c6e42dcb274763476d87af2c0597e89e022100c59e3c13b96b316cae9fa0ab0260612c7a133a6fe2b3445b6bf80b3123bf274d");

  expect(key.verify(Sha256Hash.ZERO_HASH.bytes, new ECDSASignature.fromDER(sig)), isTrue);
}

void _testSignatureDEREncoding() {
  String derSig = "304502206faa2ebc614bf4a0b31f0ce4ed9012eb193302ec2bcaccc7ae8bb40577f47549022100c73a1a1acc209f3f860bf9b9f5e13e9433db6f8b7bd527a088a0e0cd0a4c83e9";

  ECDSASignature sig = new ECDSASignature.fromDER(Utils.hexToBytes(derSig));
  String encoded = Utils.bytesToHex(sig.encodeToDER());
  expect(encoded, equals(derSig));
}


void _testASN1Roundtrip() {
    Uint8List privkeyASN1 = Utils.hexToBytes(
            "3082011302010104205c0b98e524ad188ddef35dc6abba13c34a351a05409e5d285403718b93336a4aa081a53081a2020101302c06072a8648ce3d0101022100fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f300604010004010704410479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141020101a144034200042af7a2aafe8dafd7dc7f9cfb58ce09bda7dce28653ab229b98d1d3d759660c672dd0db18c8c2d76aa470448e876fc2089ab1354c01a6e72cefc50915f4a963ee");
    KeyPair decodedKey = new KeyPair.fromASN1(privkeyASN1);

    // Now re-encode and decode the ASN.1 to see if it is equivalent (it does not produce the exact same byte
    // sequence, some integers are padded now).
    KeyPair roundtripKey = new KeyPair.fromASN1(decodedKey.toASN1());

    expect(roundtripKey.privateKeyBytes, equals(decodedKey.privateKeyBytes));

    for (KeyPair key in [decodedKey, roundtripKey]) {
        Uint8List message = Utils.reverseBytes(Utils.hexToBytes(
                "11da3761e86431e4a54c176789e41f1651b324d240d599a7067bee23d328ec2a"));
        ECDSASignature output = key.sign(new Sha256Hash(message));
        expect(key.verify(message, output), isTrue);

        output = new ECDSASignature.fromDER(Utils.hexToBytes(
                "304502206faa2ebc614bf4a0b31f0ce4ed9012eb193302ec2bcaccc7ae8bb40577f47549022100c73a1a1acc209f3f860bf9b9f5e13e9433db6f8b7bd527a088a0e0cd0a4c83e9"));
        expect(key.verify(message, output), isTrue);
    }

    // Try to sign with one key and verify with the other.
    Uint8List message = Utils.reverseBytes(Utils.hexToBytes(
        "11da3761e86431e4a54c176789e41f1651b324d240d599a7067bee23d328ec2a"));
    expect(roundtripKey.verify(message, decodedKey.sign(new Sha256Hash(message))), isTrue);
    expect(decodedKey.verify(message, roundtripKey.sign(new Sha256Hash(message))), isTrue);
}


void _testKeyPairRoundtrip() {
  Uint8List privkeyASN1 = Utils.hexToBytes(
          "3082011302010104205c0b98e524ad188ddef35dc6abba13c34a351a05409e5d285403718b93336a4aa081a53081a2020101302c06072a8648ce3d0101022100fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f300604010004010704410479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141020101a144034200042af7a2aafe8dafd7dc7f9cfb58ce09bda7dce28653ab229b98d1d3d759660c672dd0db18c8c2d76aa470448e876fc2089ab1354c01a6e72cefc50915f4a963ee");
  KeyPair decodedKey = new KeyPair.fromASN1(privkeyASN1);

  // Now re-encode and decode the ASN.1 to see if it is equivalent (it does not produce the exact same byte
  // sequence, some integers are padded now).
  KeyPair roundtripKey =
      new KeyPair.private(decodedKey.privateKeyBytes, publicKey: decodedKey.publicKey);

  for (KeyPair key in [decodedKey, roundtripKey]) {
      Uint8List message = Utils.reverseBytes(Utils.hexToBytes(
              "11da3761e86431e4a54c176789e41f1651b324d240d599a7067bee23d328ec2a"));
      ECDSASignature output = key.sign(new Sha256Hash(message));
      expect(key.verify(message, output), isTrue);

      output = new ECDSASignature.fromDER(Utils.hexToBytes(
              "304502206faa2ebc614bf4a0b31f0ce4ed9012eb193302ec2bcaccc7ae8bb40577f47549022100c73a1a1acc209f3f860bf9b9f5e13e9433db6f8b7bd527a088a0e0cd0a4c83e9"));
      expect(key.verify(message, output), isTrue);
  }

  // Try to sign with one key and verify with the other.
  Uint8List message = Utils.reverseBytes(Utils.hexToBytes(
      "11da3761e86431e4a54c176789e41f1651b324d240d599a7067bee23d328ec2a"));
  expect(roundtripKey.verify(message, decodedKey.sign(new Sha256Hash(message))), isTrue);
  expect(decodedKey.verify(message, roundtripKey.sign(new Sha256Hash(message))), isTrue);
}


//void _base58Encoding() {
//  String addr = "mqAJmaxMcG5pPHHc3H3NtyXzY7kGbJLuMF";
//  String privkey = "92shANodC6Y4evT5kFzjNFQAdjqTtHAnDTLzqBBq4BbKUPyx6CD";
//  KeyPair key = new DumpedPrivateKey(TestNet3Params.get(), privkey).getKey();
//  expect(privkey, key.getPrivateKeyEncoded(TestNet3Params.get()).toString());
//  expect(addr, key.toAddress(TestNet3Params.get()).toString());
//}


//void _base58Encoding_leadingZero() {
//    String privkey = "91axuYLa8xK796DnBXXsMbjuc8pDYxYgJyQMvFzrZ6UfXaGYuqL";
//    KeyPair key = new DumpedPrivateKey(TestNet3Params.get(), privkey).getKey();
//    expect(privkey, key.getPrivateKeyEncoded(TestNet3Params.get()).toString());
//    expect(0, key.getPrivKeyBytes()[0]);
//}


//void _base58Encoding_stress() {
//    // Replace the loop bound with 1000 to get some keys with leading zero byte
//    for (int i = 0 ; i < 20 ; i++) {
//        KeyPair key = new KeyPair();
//        KeyPair key1 = new DumpedPrivateKey(TestNet3Params.get(),
//                key.getPrivateKeyEncoded(TestNet3Params.get()).toString()).getKey();
//        expect(Utils.bytesToHex(key.getPrivKeyBytes()),
//                Utils.bytesToHex(key1.getPrivKeyBytes()));
//    }
//}


void _signTextMessage() {
  KeyPair key = new KeyPair();
  String message = "���������";
  String signatureBase64 = key.signMessage(message);
//  print("Message signed with " + key.toAddress(MainNetParams.get()) + ": " + signatureBase64);
  // Should verify correctly.
  expect(key.verifyMessage(message, signatureBase64), isTrue);
  expect(key.verifyMessage("Evil attacker says hello!", signatureBase64), isFalse);
}


void _verifyMessage() {
  // Test vector generated by Bitcoin-Qt.
  String message = "hello";
  String sigBase64 = "HxNZdo6ggZ41hd3mM3gfJRqOQPZYcO8z8qdX2BwmpbF11CaOQV+QiZGGQxaYOncKoNW61oRuSMMF8udfK54XqI8=";
  Address expectedAddress = new Address("14YPSNPi6NSXnUxtPAsyJSuw3pv7AU3Cag", NetworkParameters.MAIN_NET);
  KeyPair key = KeyPair.signedMessageToKey(message, sigBase64);
  Address gotAddress = key.getAddress(NetworkParameters.MAIN_NET);
  expect(gotAddress, equals(expectedAddress));
}


void _keyRecovery() {
  KeyPair key = new KeyPair();
  String message = "Hello World!";
  Sha256Hash hash = new Sha256Hash.digest(Utils.stringToUTF8(message));
  ECDSASignature sig = key.sign(hash);
  key = new KeyPair.public(key.publicKey);
  bool found = false;
  for (int i = 0; i < 4; i++) {
    KeyPair key2 = KeyPair.recoverFromSignature(i, sig, hash, true);
    if (key == key2) {
      found = true;
      break;
    }
  }
  expect(found, isTrue);
}


void _testUnencryptedCreate() {
  KeyPair unencryptedKey = new KeyPair();

  // The key should initially be unencrypted.
  expect(unencryptedKey.isEncrypted, isFalse);

  // Copy the private key bytes for checking later.
  Uint8List originalPrivateKeyBytes = unencryptedKey.privateKeyBytes;

  // Encrypt the key.
  KeyPair encryptedKey = unencryptedKey.encrypt(_keyCrypter, _keyCrypter.deriveKey(_PASSWORD1));

  // The key should now be encrypted.
  expect(encryptedKey.isEncrypted, isTrue);

  // The unencrypted private key bytes of the encrypted keychain
  // should be null or all be blank.
  Uint8List privateKeyBytes = encryptedKey.privateKeyBytes;
  if (privateKeyBytes != null) {
    for (int i = 0; i < privateKeyBytes.length; i++) {
      expect(privateKeyBytes[i], equals(0));
    }
  }

  // Decrypt the key.
  unencryptedKey = encryptedKey.decrypt(_keyCrypter, _keyCrypter.deriveKey(_PASSWORD1));

  // The key should be unencrypted
  expect(unencryptedKey.isEncrypted, isFalse);

  // The reborn unencrypted private key bytes should match the
  // original private key.
  privateKeyBytes = unencryptedKey.privateKeyBytes;
//  print("Reborn decrypted private key = " + Utils.bytesToHex(privateKeyBytes));

  expect(privateKeyBytes, equals(originalPrivateKeyBytes));
}


void _testEncryptedCreate() {
  KeyPair unencryptedKey = new KeyPair();

  // Copy the private key bytes for checking later.
  Uint8List originalPrivateKeyBytes = unencryptedKey.privateKeyBytes;
//  print("Original private key = " + Utils.bytesToHex(originalPrivateKeyBytes));

  EncryptedPrivateKey encryptedPrivateKey = _keyCrypter.encrypt(unencryptedKey.privateKeyBytes, _keyCrypter.deriveKey(_PASSWORD1));
  KeyPair encryptedKey = new KeyPair.encrypted(encryptedPrivateKey, unencryptedKey.publicKey, _keyCrypter);

  // The key should initially be encrypted
  expect(encryptedKey.isEncrypted, isTrue);

  // The unencrypted private key bytes of the encrypted keychain should all be blank.
  _checkAllBytesAreZero(encryptedKey.privateKeyBytes);

  // Decrypt the key.
  KeyPair rebornUnencryptedKey = encryptedKey.decrypt(_keyCrypter, _keyCrypter.deriveKey(_PASSWORD1));

  // The key should be unencrypted
  expect(rebornUnencryptedKey.isEncrypted, isFalse);

  // The reborn unencrypted private key bytes should match the original private key.
  Uint8List privateKeyBytes = rebornUnencryptedKey.privateKeyBytes;
//  print("Reborn decrypted private key = " + Utils.bytesToHex(privateKeyBytes));

  expect(privateKeyBytes, equals(originalPrivateKeyBytes));
}


void _testEncryptionIsReversible() {
  KeyPair originalUnencryptedKey = new KeyPair();
  EncryptedPrivateKey encryptedPrivateKey = _keyCrypter.encrypt(originalUnencryptedKey.privateKeyBytes, _keyCrypter.deriveKey(_PASSWORD1));
  KeyPair encryptedKey = new KeyPair.encrypted(encryptedPrivateKey, originalUnencryptedKey.publicKey, _keyCrypter);

  // The key should be encrypted
  expect(encryptedKey.isEncrypted, isTrue);

  // Check that the key can be successfully decrypted back to the original.
  expect(KeyPair.encryptionIsReversible(originalUnencryptedKey, encryptedKey, _keyCrypter, _keyCrypter.deriveKey(_PASSWORD1)), isTrue);

  // Check that key encryption is not reversible if a password other than the original is used to generate the AES key.
  expect(KeyPair.encryptionIsReversible(originalUnencryptedKey, encryptedKey, _keyCrypter, _keyCrypter.deriveKey(_WRONG_PASSWORD)), isFalse);

  // Change one of the encrypted key bytes (this is to simulate a faulty keyCrypter).
  // Encryption should not be reversible
  Uint8List goodEncryptedPrivateKeyBytes = encryptedPrivateKey.encryptedKey;

  // Break the encrypted private key and check it is broken.
  Uint8List badEncryptedPrivateKeyBytes = new Uint8List(goodEncryptedPrivateKeyBytes.length);
  encryptedPrivateKey = new EncryptedPrivateKey(badEncryptedPrivateKeyBytes, encryptedPrivateKey.iv);
  KeyPair badEncryptedKey = new KeyPair.encrypted(encryptedPrivateKey, originalUnencryptedKey.publicKey, _keyCrypter);
  expect(KeyPair.encryptionIsReversible(originalUnencryptedKey, badEncryptedKey, _keyCrypter, _keyCrypter.deriveKey(_PASSWORD1)), isFalse);
}


void _testToString() {
  KeyPair key = new KeyPair(new BigInteger(10), false); // An example private key.

  expect(key.toString(), equals("pub:04a0434d9e47f3c86235477c7b1ae6ae5d3442d49b1943c2b752a68e2a47e247c7893aba425419bc27a3b6c7e693a24c696f794c2ed877a1593cbee53b037368d7"));
  expect(key.toStringWithPrivateKey(), equals("pub:04a0434d9e47f3c86235477c7b1ae6ae5d3442d49b1943c2b752a68e2a47e247c7893aba425419bc27a3b6c7e693a24c696f794c2ed877a1593cbee53b037368d7 priv:0a"));
}


void _keyRecoveryWithEncryptedKey() {
  KeyPair unencryptedKey = new KeyPair();
  KeyParameter aesKey =  _keyCrypter.deriveKey(_PASSWORD1);
  KeyPair encryptedKey = unencryptedKey.encrypt(_keyCrypter, aesKey);

  String message = "Goodbye Jupiter!";
  Sha256Hash hash = new Sha256Hash.digest(Utils.stringToUTF8(message));
  ECDSASignature sig = encryptedKey.sign(hash, aesKey);
  unencryptedKey = new KeyPair.public(unencryptedKey.publicKey);
  bool found = false;
  for (int i = 0; i < 4; i++) {
    KeyPair key2 = KeyPair.recoverFromSignature(i, sig, hash, true);
    if (unencryptedKey == key2) {
      found = true;
      break;
    }
  }
  expect(found, isTrue);
}


//void _roundTripDumpedPrivKey() {
//  KeyPair key = new KeyPair();
//  expect(key.isCompressed, isTrue);
//  NetworkParameters params = UnitTestParams.get();
//  String base58 = key.getPrivateKeyEncoded(params).toString();
//  KeyPair key2 = new DumpedPrivateKey(params, base58).getKey();
//  assertTrue(key2.isCompressed());
//  assertTrue(Arrays.equals(key.getPrivKeyBytes(), key2.getPrivKeyBytes()));
//  assertTrue(Arrays.equals(key.publicKey, key2.publicKey));
//}


void _clear() {
  KeyPair unencryptedKey = new KeyPair();
  KeyPair encryptedKey = (new KeyPair()).encrypt(_keyCrypter, _keyCrypter.deriveKey(_PASSWORD1));

  _checkSomeBytesAreNonZero(unencryptedKey.privateKeyBytes);
  unencryptedKey.clearPrivateKey();
  _checkAllBytesAreZero(unencryptedKey.privateKeyBytes);

  // The encryptedPrivateKey should be null in an unencrypted KeyPair anyhow but check all the same.
  expect(unencryptedKey.encryptedPrivateKey, isNull);

  _checkAllBytesAreZero(encryptedKey.privateKeyBytes);
  _checkSomeBytesAreNonZero(encryptedKey.encryptedPrivateKey.encryptedKey);
  _checkSomeBytesAreNonZero(encryptedKey.encryptedPrivateKey.iv);
  EncryptedPrivateKey epk = encryptedKey.encryptedPrivateKey;
  encryptedKey.clearPrivateKey();
  _checkAllBytesAreZero(encryptedKey.privateKeyBytes);
  if(encryptedKey.encryptedPrivateKey != null) {
    _checkAllBytesAreZero(encryptedKey.encryptedPrivateKey.encryptedKey);
    _checkAllBytesAreZero(encryptedKey.encryptedPrivateKey.iv);
  }

  _checkAllBytesAreZero(epk.encryptedKey);
  _checkAllBytesAreZero(epk.iv);
}


void _testCanonicalSigs() {
  File f = new File.fromUri(new Uri.file("../resources/sig_canonical.json"));
  List<String> vectors = json.parse(f.readAsStringSync());

  for(String vector in vectors) {
    if(!Utils.isHexString(vector))
      continue;
    expect(TransactionSignature.isEncodingCanonical(Utils.hexToBytes(vector)), isTrue,
    reason: "expected canonical: $vector");
  }
}

void _testNonCanonicalSigs() {
  File f = new File.fromUri(new Uri.file("../resources/sig_noncanonical.json"));
  List<String> vectors = json.parse(f.readAsStringSync());

  for(String vector in vectors) {
    if(!Utils.isHexString(vector))
      continue;
    expect(TransactionSignature.isEncodingCanonical(Utils.hexToBytes(vector)), isFalse,
        reason: "expected noncanonical: $vector");
  }
}


void _testCreatedSigAndPubkeyAreCanonical() {
  // Tests that we will not generate non-canonical pubkeys or signatures
  // We dump failed data to error log because this test is not expected to be deterministic
  KeyPair key = new KeyPair();
  if(!key.isPubKeyCanonical) {
    print(Utils.bytesToHex(key.publicKey));
    fail("we must not generate non-canonical pubkeys");
  }

  Uint8List hash = new Uint8List(32);
  Random r = new Random();
  for(int i = 0 ; i < 32 ; i++)
    hash[i] = r.nextInt(255);
  Uint8List sigBytes = key.sign(new Sha256Hash(hash)).encodeToDER();
  Uint8List encodedSig = new Uint8List(sigBytes.length + 1);
  encodedSig.setRange(0, sigBytes.length, sigBytes);
  encodedSig[sigBytes.length] = SigHash.ALL.value;
  if (!TransactionSignature.isEncodingCanonical(encodedSig)) {
    print(Utils.bytesToHex(sigBytes));
    fail("we must not generate non-canonical signatures");
  }
}

void _checkSomeBytesAreNonZero(Uint8List bytes) {
  if (bytes == null) fail("checkSomeBytesAreNonZero");
  for (int b in bytes) if (b != 0) return;
  fail("checkSomeBytesAreNonZero");
}

void _checkAllBytesAreZero(Uint8List bytes) {
  if (bytes == null) return;
  for (int b in bytes) if (b != 0) fail("checkAllBytesAreZero");
}





void main() {
  group("core.KeyPair", () {
    test("keypair_address1", () => _testAddress(_testPubKey1, _testAddress1));
    test("keypair_privpub1", () => _testPrivToPub(_testPubKey1, _testPrivKey1));
    test("keypair_clear", () => _testClear(_testPrivKey1));
    test("keypair_equals_hashcode", () => _testEqualsAndHashCode(_testPrivKey1, _testPubKey1));
    group("bitcoinj", () {
      setUp(() => _setUp());
      test("sValue", () => _sValue());
      test("signatures", () => _testSignatures());
      test("signatureDERencoding", () => _testSignatureDEREncoding());
      test("asn1roundtrip", () => _testASN1Roundtrip());
      test("keypairRoundtrip", () => _testKeyPairRoundtrip());
      test("signTextMessage", () => _signTextMessage());
      test("verifyMessage", () => _verifyMessage());
      test("keyRecovery", () => _keyRecovery());
      test("unencryptedCreate", () => _testUnencryptedCreate());
      test("encryptedCreate", () => _testEncryptedCreate());
      test("encryptionIsReversible", () => _testEncryptionIsReversible());
      test("toString", () => _testToString());
      test("keyRecoveryWithExcryptedKey", () => _keyRecoveryWithEncryptedKey());
      test("clear", () => _clear());
      test("createdSigsAndPubkeysAreCanonical", () => _testCreatedSigAndPubkeyAreCanonical());
      test("canonicalSigs", () => _testCanonicalSigs());
      test("nonCanonicalSigs", () => _testNonCanonicalSigs());
    });
  });
}







