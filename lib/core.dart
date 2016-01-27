library dartcoin.core;


import "package:cryptoutils/cryptoutils.dart";

import "dart:collection";
import "dart:convert";
import "dart:typed_data";
import "dart:math";
import "package:crypto/crypto.dart" hide CryptoUtils, Hash;
import "package:bignum/bignum.dart";
import "package:collection/equality.dart";
import "package:collection/algorithms.dart" show binarySearch;//TODO remove

import "package:pointycastle/api.dart";

// tmp
import "package:asn1lib/asn1lib.dart";


import "package:dartcoin/src/utils.dart" as utils;
import "package:dartcoin/src/crypto.dart" as crypto;

import "package:dartcoin/script.dart";
import "package:dartcoin/utils/byte_sink.dart";


// utils
part "src/core/units.dart";

// serialization
part "src/serialization/varint.dart";
part "src/serialization/varstr.dart";
part "src/serialization/bitcoin_serializable.dart";
part "src/serialization/bitcoin_serialization.dart";
part "src/serialization/serialization_exception.dart";

// addresses and private keys
part "src/core/address.dart";
part "src/core/keypair.dart";
part "src/core/transaction_signature.dart";
// private key security
part "src/crypto/key_crypter.dart";
part "src/crypto/key_crypter_exception.dart";
part "src/crypto/key_crypter_scrypt.dart";
part "src/crypto/encrypted_private_key.dart";

// network settings
part "src/core/params/network_parameters.dart";
part "src/core/params/main_net.dart";
part "src/core/params/test_net.dart";
part "src/core/params/unit_test.dart";

// transactions
part "src/core/transaction.dart";
part "src/core/transaction_input.dart";
part "src/core/transaction_outpoint.dart";
part "src/core/transaction_output.dart";

// blocks
part "src/core/block.dart";
part "src/core/verification_exception.dart";

// bloom filters
part "src/core/bloom_filter.dart";
part "src/core/filtered_block.dart";
part "src/core/partial_merkle_tree.dart";


// wire
part "src/wire/inventory_item.dart";
part "src/wire/message.dart";
part "src/wire/peer_address.dart";
// messages
part "src/wire/messages/version_message.dart";
part "src/wire/messages/verack_message.dart";
part "src/wire/messages/address_message.dart";
part "src/wire/messages/inventory_item_container_message.dart";
part "src/wire/messages/inventory_message.dart";
part "src/wire/messages/getdata_message.dart";
part "src/wire/messages/notfound_message.dart";
part "src/wire/messages/request_message.dart";
part "src/wire/messages/getblocks_message.dart";
part "src/wire/messages/getheaders_message.dart";
part "src/wire/messages/transaction_message.dart";
part "src/wire/messages/block_message.dart";
part "src/wire/messages/headers_message.dart";
part "src/wire/messages/getaddress_message.dart";
part "src/wire/messages/mempool_message.dart";
part "src/wire/messages/ping_message.dart";
part "src/wire/messages/pong_message.dart";
part "src/wire/messages/alert_message.dart";
part "src/wire/messages/filterload_message.dart";
part "src/wire/messages/filteradd_message.dart";
part "src/wire/messages/filterclear_message.dart";
part "src/wire/messages/merkleblock_message.dart";
