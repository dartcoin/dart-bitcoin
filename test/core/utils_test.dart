library bitcoin.test.core.utils;

import "package:test/test.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:bitcoin/core.dart";
import "package:bitcoin/src/crypto.dart" as crypto;
import "package:bitcoin/src/utils.dart" as utils;

import "dart:convert";
import "dart:typed_data";

void main() {
  group("core.Utils", () {
    test("singledigest", () {
      var _testString1 = new Uint8List.fromList(new Utf8Encoder().convert(
          "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"));
      var _testHash1 = CryptoUtils
          .hexToBytes("475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca");
      expect(crypto.singleDigest(_testString1), equals(_testHash1));
    });

    test("doubledigest", () {
      var _testBytes3 = CryptoUtils.hexToBytes("00010966776006953D5567439E5E39F86A0D273BEE");
      var _testDoubleHash3 = CryptoUtils
          .hexToBytes("D61967F63C7DD183914A4AE452C9F6AD5D462CE3D277798075B107615C1A8A30");
      expect(crypto.doubleDigest(_testBytes3), equals(_testDoubleHash3));
    });

    test("ripemd160", () {
      var bytes = CryptoUtils
          .hexToBytes("600FFE422B4E00731A59557A5CCA46CC183944191006324A447BDB2D98D4B408");
      var hash = CryptoUtils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
      expect(crypto.ripemd160Digest(bytes), equals(hash));
    });

    test("sha1", () {
      var message = new Uint8List.fromList(new Utf8Encoder().convert("test-dartcoin"));
      var hash = CryptoUtils.hexToBytes("7db8dc1e20c72e5f7db948bcacec8c1503fbbe1c");
      expect(crypto.sha1Digest(message), equals(hash));
    });

    test("sha256hash160", () {
      var input = CryptoUtils.hexToBytes(
          "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6");
      var hash = CryptoUtils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
      expect(crypto.sha256hash160(input), equals(hash));
    });

    test("hexToBytes", () {
      // bytesToHex is a dart native function, so we can use it to test the reverse operation
      var byteString =
          "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
      var bytes = CryptoUtils.hexToBytes(byteString);
      expect(CryptoUtils.bytesToHex(bytes), equalsIgnoringCase(byteString));
    });

    test("isHexString", () {
      expect(utils.isHexString("11"), isTrue, reason: "11");
      expect(utils.isHexString(CryptoUtils.bytesToHex(utils.stringToUTF8("Steven"))), isTrue,
          reason: "steven to utf8");
      expect(utils.isHexString(" abd DFB109"), isTrue, reason: " abd DFB109");
      expect(utils.isHexString("Steven"), isFalse, reason: "Steven");
    });

    test("formatMessageForSigning", () {
      //TODO
    });

    test("equallists", () {
      var hash = CryptoUtils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
      var hash2 = CryptoUtils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
      var hash3 = CryptoUtils
          .hexToBytes("475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca");
      var list1 = [new Hash256(hash3), new Hash256(hash3)];
      var list2 = [new Hash256(hash3), new Hash256(hash3)];
      expect(utils.equalLists(hash, hash2), isTrue);
      expect(utils.equalLists(hash, hash), isTrue);
      expect(utils.equalLists(hash, hash3), isFalse);
      expect(utils.equalLists(list1, list2), isTrue);
    });

    test("bigintToBytes", () {
      //TODO
    });

    test("uintToBytes", () {
      //TODO all variants
    });

    //test("ipv6encoding", () => _ipv6EncodingTest());
    // bitcoinj
    test("toSatoshi", () {
      // String version
      expect(Units.toSatoshi(0.01), equals(Units.CENT));
      expect(Units.toSatoshi(1E-2), equals(Units.CENT));
      expect(Units.toSatoshi(1.01), equals(Units.COIN + Units.CENT));
      expect(Units.toSatoshi(21000000), equals(NetworkParameters.MAX_MONEY));
    });

    test("reverseBytes", () {
      expect(utils.reverseBytes(new Uint8List.fromList([5, 4, 3, 2, 1])),
          equals(new Uint8List.fromList([1, 2, 3, 4, 5])));
    });
  });
}
