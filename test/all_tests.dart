library dartcoin.test.all;

import "core/address_test.dart" as address;
import "core/base58check_test.dart" as base58check;
import "core/block_test.dart" as block;
import "core/filtered_block_and_partial_merkle_tree_test.dart" as filtered_block_and_partial_merkle_tree;
import "core/keypair_test.dart" as keypair;
import "core/sha256hash_test.dart" as sha256hash;

import "core/utils_test.dart" as utils;

// crypto
import "crypto/key_crypter_scrypt_test.dart" as key_crypter_scrypt;

// serialization
import "serialization/varint_test.dart" as varint; 

// hash representation
import "hash/hash_representation_test.dart" as hash_representation;

// wire
import "wire/bloom_filter_test.dart" as bloom_filter;
import "wire/message_serialization_test.dart" as message_serialization;
import "wire/peer_address_test.dart" as peer_address;


void main() {
  // core
  address.main();
  base58check.main();
  block.main();
  filtered_block_and_partial_merkle_tree.main();
  keypair.main();
  sha256hash.main();
  
  utils.main();
  // crypto
  // TODO not yet working key_crypter_scrypt.main();
  // serialization
  varint.main();
  // hash representation
  hash_representation.main();
  // wire
  bloom_filter.main();
  message_serialization.main();
  peer_address.main();
}

