
library dartcoin.src.crypto;

import "dart:typed_data";

import "package:pointycastle/digests/ripemd160.dart";
import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/digests/sha1.dart";

// cherry picking cipher dependencies
import "package:cipher/api.dart";
import "package:cipher/api/ecc.dart";
import "package:cipher/block/aes_fast.dart";
import "package:cipher/digests/sha512.dart";//
import "package:cipher/ecc/ecc_base.dart";
import "package:cipher/ecc/ecc_fp.dart" as fp;
import "package:cipher/key_derivators/pbkdf2.dart";//
import "package:cipher/key_derivators/scrypt.dart";
import "package:cipher/macs/hmac.dart";//
import "package:cipher/modes/cbc.dart";
import "package:cipher/paddings/padded_block_cipher.dart";
import "package:cipher/paddings/pkcs7.dart";
import "package:cipher/params/asymmetric_key_parameter.dart";
import "package:cipher/params/key_derivators/pbkdf2_parameters.dart";
import "package:cipher/params/key_derivators/scrypt_parameters.dart";
import "package:cipher/params/key_parameter.dart";
import "package:cipher/params/padded_block_cipher_parameters.dart";
import "package:cipher/params/parameters_with_iv.dart";
import "package:cipher/signers/ecdsa_signer.dart";

import "package:dartcoin/src/utils.dart" as utils;


/**
 * Calculates the SHA-256 hash of the input data.
 */
Uint8List singleDigest(Uint8List input) =>
    new SHA256Digest().process(input);

/**
 * Calculates the double-round SHA-256 hash of the input data.
 */
Uint8List doubleDigest(Uint8List input) =>
    new SHA256Digest().process(new SHA256Digest().process(input));

/**
 * Calculates the double-round SHA-256 hash of the input data concatenated together.
 */
Uint8List doubleDigestTwoInputs(Uint8List input1, Uint8List input2) =>
    doubleDigest(utils.concatBytes(input1, input2));

/**
 * Calculates the RIPEMD-160 hash of the given input.
 */
Uint8List ripemd160Digest(Uint8List input) => //TODO refactor hash160
    new RIPEMD160Digest().process(input);

/**
 * Calculates the SHA-1 hash of the given input.
 */
Uint8List sha1Digest(Uint8List input) =>
    new SHA1Digest().process(input);

/**
 * Calculates the RIPEMD-160 hash of the SHA-256 hash of the input.
 * This is used to convert an ECDSA public key to a Bitcoin address.
 */
Uint8List sha256hash160(Uint8List input) =>
    ripemd160Digest(singleDigest(input));