library bitcoin.core;

import "dart:collection";
import "dart:typed_data";
import "dart:math";

import "package:cryptoutils/cryptoutils.dart";
import "package:base58check/base58check.dart";
import "package:bytes/bytes.dart" as bytes;
import "package:collection/collection.dart";

import "package:pointycastle/api.dart";
import "package:pointycastle/ecc/ecc_fp.dart" as fp;
import "package:pointycastle/ecc/api.dart";
import "package:pointycastle/signers/ecdsa_signer.dart";
import "package:pointycastle/macs/hmac.dart";
import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/ecc/curves/secp256k1.dart";

// tmp
import "package:asn1lib/asn1lib.dart";

import "package:bitcoin/src/utils.dart" as utils;
import "package:bitcoin/src/crypto.dart" as crypto;

import "package:bitcoin/script.dart";
import "package:bitcoin/scripts/common.dart";

import "package:bitcoin/src/wire/serialization.dart";

// utils
part "src/core/units.dart";

// addresses and private keys
part "src/core/address.dart";
part "src/core/keypair.dart";
part "src/core/sig_hash.dart";
part "src/core/transaction_signature.dart";
// private key security
part "src/crypto/key_crypter.dart";
part "src/crypto/key_crypter_exception.dart";
part "src/crypto/encrypted_private_key.dart";

// network settings
part "src/core/params/network_parameters.dart";
part "src/core/params/main_net_params.dart";
part "src/core/params/test_net_params.dart";
part "src/core/params/unit_test_params.dart";

// transactions
part "src/core/transaction.dart";
part "src/core/transaction_input.dart";
part "src/core/transaction_outpoint.dart";
part "src/core/transaction_output.dart";

// blocks
part "src/core/block.dart";
part "src/core/block_header.dart";
part "src/core/verification_exception.dart";

// bloom filters
part "src/core/bloom_filter.dart";
part "src/core/filtered_block.dart";
part "src/core/partial_merkle_tree.dart";
