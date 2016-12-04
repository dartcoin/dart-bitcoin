library dartcoin.test.core.sha256hash;


import "package:test/test.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:dartcoin/src/crypto.dart" as crypto;

import "dart:typed_data";
import "dart:convert";

Map vectors = {
  "single": [
    [
      UTF8.encode("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"),
      "475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca"
    ],
    [
      UTF8.encode("x"),
      "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881"
    ]
  ],

  "double": [
    [
      "00010966776006953D5567439E5E39F86A0D273BEE",
      "D61967F63C7DD183914A4AE452C9F6AD5D462CE3D277798075B107615C1A8A30"
    ],
    [
      "646572730000000000520000005d4fab8101010000006fe28c0ab6f1b372c1a6a246ae6a",
      "9416b146fa084df69c981de891f6c8f4ac8b9d9dedc42f6f2530a40b61e02f6a"
    ],
    [
      "01e215104d010000000000000000000000000000000000ffff0a000001208d",
      "ed52399b568ed8d59a83729c116f87d0bef284e998f3477c9861169ab12eed5c"
    ]
  ],
};


void main() {
  group("crypto.SHA-256", () {

    test("Hash256",   () {
      var hashBytes = CryptoUtils.hexToBytes(vectors["single"][0][1]);
      var hash = new Hash256(hashBytes);
      expect(hash.asBytes(), equals(hashBytes));
      expect(hash.toHex(), equalsIgnoringCase(CryptoUtils.bytesToHex(hashBytes)));
      expect(hash.toString(), equalsIgnoringCase(CryptoUtils.bytesToHex(hashBytes)));
      var hash3 = new Hash256(hashBytes);
      expect(hash == hash3, isTrue);
      expect(hash.hashCode == hash3.hashCode, isTrue);
      var hash4 = new Hash256(crypto.singleDigest(new Uint8List(2)));
      expect(hash4 == hash, isFalse);
    });

    test("crypto.singleDigest", () {
      for (List vector in vectors["single"]) {
        var input = vector[0];
        var output = vector[1];
        if(input is String) {
          input = CryptoUtils.hexToBytes(input);
        }

        var hash = new Hash256(crypto.singleDigest(input));
        var hashString = hash.toHex();
        expect(hashString, equalsIgnoringCase(output));
      }
    });

    test("crypto.DoubleDigest", () {
      for (List vector in vectors["double"]) {
        var input = vector[0];
        var output = vector[1];
        if(input is String) {
          input = CryptoUtils.hexToBytes(input);
        }

        var hash = new Hash256(crypto.doubleDigest(input));
        var hashString = hash.toHex();
        expect(hashString, equalsIgnoringCase(output));
      }
    });

    test("DoubleSHA256Digest class", () {
      for (List vector in vectors["double"]) {
        var input = vector[0];
        var output = vector[1];
        if(input is String) {
          input = CryptoUtils.hexToBytes(input);
        }

        crypto.DoubleSHA256Digest digest = new crypto.DoubleSHA256Digest();
        digest.update(input, 0, input.length);
        var hash = new Uint8List(digest.digestSize);
        digest.doFinal(hash, 0);
        var hashString = CryptoUtils.bytesToHex(hash);
        expect(hashString, equalsIgnoringCase(output));
      }
    });


  });
}
