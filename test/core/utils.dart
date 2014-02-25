library dartcoin.test.core.utils;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "dart:convert";
import "dart:typed_data";

void _testSingleDigest() {
  var _testString1 = new Uint8List.fromList(new Utf8Encoder().convert("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"));
  var _testHash1 = Utils.hexToBytes("475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca");
  expect(Utils.singleDigest(_testString1), equals(_testHash1));
}

void _testDoubleDigest() {
  var _testBytes3 = Utils.hexToBytes("00010966776006953D5567439E5E39F86A0D273BEE");
  var _testDoubleHash3 = Utils.hexToBytes("D61967F63C7DD183914A4AE452C9F6AD5D462CE3D277798075B107615C1A8A30");
  expect(Utils.doubleDigest(_testBytes3), equals(_testDoubleHash3));
}

void _ripemd160() {
  var bytes = Utils.hexToBytes("600FFE422B4E00731A59557A5CCA46CC183944191006324A447BDB2D98D4B408");
  var hash = Utils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
  expect(Utils.ripemd160Digest(bytes), equals(hash));
}

void _sha1digest() {
  //TODO
}

void _sha256hash160() {
  var input = Utils.hexToBytes("0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6");
  var hash = Utils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
  expect(Utils.sha256hash160(input), equals(hash));
}

void _hexToBytes() {
  // bytesToHex is a dart native function, so we can use it to test the reverse operation
  var byteString = "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
  var bytes = Utils.hexToBytes(byteString);
  expect(Utils.bytesToHex(bytes), equalsIgnoringCase(byteString));
}

void _formatMessageForSigning() {
  //TODO
}

void _equalList() {
  var hash = Utils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
  var hash2 = Utils.hexToBytes("010966776006953D5567439E5E39F86A0D273BEE");
  var hash3 = Utils.hexToBytes("475dbd9278ce464097f8dd241b088ac96615bfdea9e496bc05828aca94aabfca");
  var list1 = [new Sha256Hash(hash3), new Sha256Hash(hash3)];
  var list2 = [new Sha256Hash(hash3), new Sha256Hash(hash3)];
  expect(Utils.equalLists(hash, hash2), isTrue);
  expect(Utils.equalLists(hash, hash), isTrue);
  expect(Utils.equalLists(hash, hash3), isFalse);
  expect(Utils.equalLists(list1, list2), isTrue);
}

void _bigIntToBytes() {
  //TODO
}

void _uintsToBytes() {
  //TODO all variants
}

void main() {
  test("utils_singledigest", () => _testSingleDigest());
  test("utils_doubledigest", () => _testDoubleDigest());
  test("utils_ripemd160", () => _ripemd160());
  test("utils_sha1", () => _sha1digest());
  test("utils_sha256hash160", () => _sha256hash160());
  test("utils_hexToBytes", () => _hexToBytes());
  test("utils_formatMessageForSigning", () => _formatMessageForSigning());
  test("utils_equallists", () => _equalList());
  test("utils_bigintToBytes", () => _bigIntToBytes());
  test("utils_uintToBytes", () => _uintsToBytes());
}










