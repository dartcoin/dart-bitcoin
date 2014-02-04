library dartcoin.test.core.address;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

void _testAddress(String hexBytes, String address, [int version]) {
  if(version == null)
    version = NetworkParameters.MAIN_NET.addressHeader;
  var bytes = Utils.hexToBytes(hexBytes);
  var addy = new Address(bytes);
  expect(addy.toString(), equals(address));
  expect(addy.version, equals(version));
}

void _testAddressReverse(String address, String hexBytes, [int version]) {
  if(version == null)
    version = NetworkParameters.MAIN_NET.addressHeader;
  var addy = new Address(address);
  var bytes = Utils.hexToBytes(hexBytes);
  expect(addy.hash160, orderedEquals(bytes));
  expect(addy.version, equals(version));
}

void main() {
  test("address_encode1", () { _testAddress("010966776006953D5567439E5E39F86A0D273BEE", "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"); });
  test("address_encode2", () { _testAddress("00010966776006953D5567439E5E39F86A0D273BEED61967F6", "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"); });
  test("address_decode1", () { _testAddressReverse("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", "010966776006953D5567439E5E39F86A0D273BEE"); });
  
  //TODO tests for other network parameters
}