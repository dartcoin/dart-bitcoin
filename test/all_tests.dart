library dartcoin.test.all;

import "core/address.dart" as address;
import "core/base58check.dart" as base58check;
import "core/block.dart" as block;
import "core/keypair.dart" as keypair;
import "core/sha256hash.dart" as sha256hash;

import "core/utils.dart" as utils;



void main() {
  address.main();
  base58check.main();
  block.main();
  keypair.main();
  sha256hash.main();
  utils.main();
}

