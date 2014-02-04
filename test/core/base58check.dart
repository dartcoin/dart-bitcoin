library dartcoin.test.core.base58check;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

main() {
  test("base58check_encode1", () { expect(
      Base58Check.encode(Utils.hexToBytes("00010966776006953D5567439E5E39F86A0D273BEED61967F6")), equals("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM")); });
  test("base58check_decode1", () { expect(Base58Check.decode("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"), equals(Utils.hexToBytes("00010966776006953D5567439E5E39F86A0D273BEED61967F6"))); });
}