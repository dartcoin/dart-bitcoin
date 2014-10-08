library dartcoin.test.core.sha256hash;


import "package:unittest/unittest.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:dartcoin/core/core.dart";

import "dart:typed_data";
import "dart:convert";

var _testString1 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
var _testHash1 = "475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca";
var _testString2 = "x";
var _testHash2 = "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881";
var _testBytes3 = "00010966776006953D5567439E5E39F86A0D273BEE";
var _testDoubleHash3 = "D61967F63C7DD183914A4AE452C9F6AD5D462CE3D277798075B107615C1A8A30";

void _testEqualsAndHashcode(Uint8List hashBytes) {
  var hash = new Hash256(hashBytes);
  expect(hash.asBytes(), equals(hashBytes));
  expect(hash.toHex(), equalsIgnoringCase(CryptoUtils.bytesToHex(hashBytes)));
  expect(hash.toString(), equalsIgnoringCase(CryptoUtils.bytesToHex(hashBytes)));
  var hash3 = new Hash256(hashBytes);
  expect(hash == hash3, isTrue);
  expect(hash.hashCode == hash3.hashCode, isTrue);
  var hash4 = new Hash256(Utils.singleDigest(new Uint8List(2)));
  expect(hash4 == hash, isFalse);
}

void _testSingle(var input, var output) {
  if(input is String) {
    input = new Uint8List.fromList(new Utf8Encoder().convert(input));
  }
  var hash = new Hash256(Utils.singleDigest(input));
  var hashString = hash.toHex();
  expect(hashString, equalsIgnoringCase(output));
}

void _testDouble(var input, var output) {
  if(input is String) {
    input = new Uint8List.fromList(new Utf8Encoder().convert(input));
  }
  var hash = new Hash256(Utils.doubleDigest(input));
  var hashString = hash.toHex();
  expect(hashString, equalsIgnoringCase(output));
}

void main() {
  group("core.Sha256Hash", () {
    test("sha256hash_bytes",   () => _testEqualsAndHashcode(CryptoUtils.hexToBytes(_testDoubleHash3)));
    test("sha256hash_single1", () => _testSingle(_testString1, _testHash1));
    test("sha256hash_single2", () => _testSingle(_testString2, _testHash2));
    test("sha256hash_double1", () => _testDouble(CryptoUtils.hexToBytes(_testBytes3), _testDoubleHash3));
  });
}
