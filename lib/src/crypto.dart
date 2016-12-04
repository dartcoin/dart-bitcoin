
library dartcoin.src.crypto;

import "dart:typed_data";

import "package:pointycastle/digests/ripemd160.dart";
import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/digests/sha1.dart";
import "package:pointycastle/src/impl/base_digest.dart";

import "package:dartcoin/src/utils.dart" as utils;


class DoubleSHA256Digest extends BaseDigest {//TODO pointycastle registry

  SHA256Digest _internal = new SHA256Digest();

  DoubleSHA256Digest();

  @override
  String get algorithmName => "SHA-256d";

  @override
  int get digestSize => _internal.digestSize;

  @override
  void reset() => _internal.reset();

  @override
  void updateByte(int inp) => _internal.updateByte(inp);

  @override
  void update(Uint8List inp, int inpOff, int len) =>
      _internal.update(inp, inpOff, len);

  @override
  int doFinal(Uint8List out, int outOff) {
    Uint8List firstSum = new Uint8List(digestSize);
    _internal.doFinal(firstSum, 0);
    SHA256Digest secondDigest = new SHA256Digest();
    secondDigest.update(firstSum, 0, firstSum.length);
    return secondDigest.doFinal(out, outOff);
  }
}


/**
 * Calculates the SHA-256 hash of the input data.
 */
Uint8List singleDigest(Uint8List input) =>
    new SHA256Digest().process(input);

/**
 * Calculates the double-round SHA-256 hash of the input data.
 */
Uint8List doubleDigest(Uint8List input) =>
    new DoubleSHA256Digest().process(input);

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