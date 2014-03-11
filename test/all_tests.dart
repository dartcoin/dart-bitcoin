library dartcoin.test.all;

import "core/address_test.dart" as address;
import "core/base58check_test.dart" as base58check;
import "core/block_test.dart" as block;
import "core/keypair_test.dart" as keypair;
import "core/sha256hash_test.dart" as sha256hash;

import "core/utils_test.dart" as utils;

import "serialization/varint_test.dart" as varint; 



void main() {
  // core
  address.main();
  base58check.main();
  block.main();
  keypair.main();
  sha256hash.main();
  utils.main();
  // serialization
  varint.main();
}

