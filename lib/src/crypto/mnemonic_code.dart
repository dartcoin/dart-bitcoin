library bitcoin.crypto.mnemonic_code;

import "dart:convert" show utf8;
import "dart:typed_data";

import "package:cryptoutils/cryptoutils.dart";
import "package:pointycastle/api.dart";
import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/digests/sha512.dart";
import "package:pointycastle/key_derivators/api.dart";
import "package:pointycastle/key_derivators/pbkdf2.dart";
import "package:pointycastle/macs/hmac.dart";

import "package:bitcoin/src/crypto.dart" as crypto;
import "package:bitcoin/src/utils.dart" as utils;

/**
 * A MnemonicCode object may be used to convert between binary seed values and
 * lists of words per the BIP 39 specification.
 * 
 * For more info: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
 */
class MnemonicCode {
  static const String BIP39_ENGLISH_SHA256 =
      "ad90bf3beb7b0eb7e5acd74727dc0da96e0a280a258354e7293fb7e211ac03db";

  static const int _PBKDF2_ROUNDS = 2048;

  List<String> _wordList;

  /**
   * Creates a [MnemonicCode] object using the [wordList] word list.
   * 
   * If [wordListDigest] is not [null], the SHA-256 digest of the [wordList] will be checked.
   * If [wordListDigest] is omitted, [BIP39_ENGLISH_SHA256] will be used.
   * So [null] should be passed explicitly to avoid the digest check.
   */
  MnemonicCode(Iterable<String> wordList, [String wordListDigest = BIP39_ENGLISH_SHA256]) {
    if (wordList.length != 2048)
      throw new ArgumentError("The word list does not contain exactly 2048 words.");

    _wordList = new List<String>();
    SHA256Digest md = new SHA256Digest();
    for (String word in wordList) {
      List<int> wordBytes = utf8.encode(word);
      md.update(wordBytes, 0, wordBytes.length);
      _wordList.add(word);
    }
    if (wordListDigest != null) {
      Uint8List digest = new Uint8List(md.digestSize);
      md.doFinal(digest, 0);
      if (!utils.equalLists(digest, CryptoUtils.hexToBytes(wordListDigest)))
        throw new ArgumentError("Invalid wordlist digest");
    }
  }

  /**
   * Convert mnemonic word list to seed.
   */
  static Uint8List toSeed(List<String> words, String passphrase) {
    // To create binary seed from mnemonic, we use PBKDF2 function
    // with mnemonic sentence (in UTF-8) used as a password and
    // string "mnemonic" + passphrase (again in UTF-8) used as a
    // salt. Iteration count is set to 2048 and HMAC-SHA512 is
    // used as a pseudo-random function. Desired length of the
    // derived key is 512 bits (= 64 bytes).
    //
    Uint8List pass = utils.utf8Encode(words.join(" "));
    Uint8List salt = utils.utf8Encode("mnemonic" + passphrase);

    KeyDerivator deriv = new PBKDF2KeyDerivator(new HMac(new SHA512Digest(), 128));
    deriv.init(new Pbkdf2Parameters(salt, _PBKDF2_ROUNDS, 64));

    return deriv.process(pass);
  }

  /**
   * Convert mnemonic word list to original entropy value.
   */
  Uint8List toEntropy(List<String> words) {
    if (words.length % 3 > 0)
      throw new MnemonicException("Word list size must be multiple of three words.");

    // Look up all the words in the list and construct the
    // concatenation of the original entropy and the checksum.
    //
    int concatLenBits = words.length * 11;
    List<bool> concatBits = new List<bool>(concatLenBits);
    int wordindex = 0;
    for (String word in words) {
      // Find the words index in the wordlist.

      int ndx = utils.binarySearch(_wordList, word);
      if (ndx < 0) throw new MnemonicException.word(word);

      // Set the next 11 bits to the value of the index.
      for (int ii = 0; ii < 11; ++ii)
        concatBits[(wordindex * 11) + ii] = (ndx & (1 << (10 - ii))) != 0;
      ++wordindex;
    }

    int checksumLengthBits = concatLenBits ~/ 33;
    int entropyLengthBits = concatLenBits - checksumLengthBits;

    // Extract original entropy as bytes.
    Uint8List entropy = new Uint8List(entropyLengthBits ~/ 8);
    for (int ii = 0; ii < entropy.length; ++ii)
      for (int jj = 0; jj < 8; ++jj) if (concatBits[(ii * 8) + jj]) entropy[ii] |= 1 << (7 - jj);

    // Take the digest of the entropy.
    Uint8List hash = crypto.singleDigest(entropy);
    List<bool> hashBits = _bytesToBits(hash);

    // Check all the checksum bits.
    for (int i = 0; i < checksumLengthBits; ++i)
      if (concatBits[entropyLengthBits + i] != hashBits[i]) throw new MnemonicException.checksum();

    return entropy;
  }

  /**
   * Convert entropy data to mnemonic word list.
   */
  List<String> toMnemonic(Uint8List entropy) {
    if (entropy.length % 4 > 0)
      throw new MnemonicException("entropy length not multiple of 32 bits");

    // We take initial entropy of ENT bits and compute its
    // checksum by taking first ENT / 32 bits of its SHA256 hash.

    Uint8List hash = crypto.singleDigest(entropy);
    List<bool> hashBits = _bytesToBits(hash);

    List<bool> entropyBits = _bytesToBits(entropy);
    int checksumLengthBits = entropyBits.length ~/ 32;

    // We append these bits to the end of the initial entropy.
    List<bool> concatBits = new List<bool>(entropyBits.length + checksumLengthBits)
      ..setRange(0, entropyBits.length, entropyBits, 0)
      ..setRange(entropyBits.length, entropyBits.length + checksumLengthBits, hashBits, 0);

    // Next we take these concatenated bits and split them into
    // groups of 11 bits. Each group encodes number from 0-2047
    // which is a position in a wordlist.  We convert numbers into
    // words and use joined words as mnemonic sentence.

    List<String> words = new List<String>();
    int nwords = concatBits.length ~/ 11;
    for (int i = 0; i < nwords; ++i) {
      int index = 0;
      for (int j = 0; j < 11; ++j) {
        index <<= 1;
        if (concatBits[(i * 11) + j]) index |= 0x1;
      }
      words.add(_wordList[index]);
    }

    return words;
  }

  /**
   * Check to see if a mnemonic word list is valid.
   */
  void check(List<String> words) {
    toEntropy(words);
  }

  List<bool> _bytesToBits(Uint8List data) {
    List<bool> bits = new List<bool>(data.length * 8);
    for (int i = 0; i < data.length; ++i)
      for (int j = 0; j < 8; ++j) bits[(i * 8) + j] = (data[i] & (1 << (7 - j))) != 0;
    return bits;
  }
}

class MnemonicException implements Exception {
  final String message;

  MnemonicException([this.message]);

  MnemonicException.word(String badWord) : this("Bad word in the mnemonic: $badWord");

  MnemonicException.checksum() : this("Invalid mnemonic checksum");

  @override
  String toString() => "MnemonicException: $message";
}
