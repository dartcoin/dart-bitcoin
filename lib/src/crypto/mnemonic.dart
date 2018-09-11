import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import "package:pointycastle/digests/sha256.dart";
import 'package:pointycastle/digests/sha512.dart';
import "package:pointycastle/key_derivators/api.dart";
import "package:pointycastle/key_derivators/pbkdf2.dart";
import 'package:pointycastle/macs/hmac.dart';

class MnemonicUtils {
  static final int SEED_ITERATIONS = 2048;
  static final int SEED_KEY_SIZE = 64;
  static List<String> WORD_LIST = null;

  /// Generate the mnemonic string list from an secure initial entropy data
  static String generateMnemonic(Uint8List initialEntropy) {
    if (WORD_LIST == null) {
      WORD_LIST = populateWordList();
    }

    validateInitialEntropy(initialEntropy);

    int ent = initialEntropy.length * 8;
    int checksumLength = ent ~/ 32;

    int checksum = calculateChecksum(initialEntropy);

    List<bool> bits = convertToBits(initialEntropy, checksum);

    int iterations = (ent + checksumLength) ~/ 11;
    StringBuffer mnemonicBuilder = new StringBuffer();
    for (int i = 0; i < iterations; i++) {
      int index = toInt(nextElevenBits(bits, i));
      mnemonicBuilder.write(WORD_LIST[index]);

      bool notLastIteration = i < iterations - 1;
      if (notLastIteration) {
        mnemonicBuilder.write(" ");
      }
    }

    return mnemonicBuilder.toString();
  }

// Generate the master seed from the mnemonic and the passphrase [The passphrase is optional]
  static Uint8List generateMasterSeed(String mnemonic, String passphrase) {
    validateMnemonic(mnemonic);
    passphrase = passphrase == null ? "" : passphrase;

    String salt = "mnemonic$passphrase";
    KeyDerivator derivator =
    new PBKDF2KeyDerivator(new HMac(new SHA512Digest(), 128));
    derivator.init(new Pbkdf2Parameters(
        utf8.encode(salt), SEED_ITERATIONS, SEED_KEY_SIZE));

    var masterSeedByteArray = derivator.process(utf8.encode(mnemonic));

    return masterSeedByteArray;
  }

  static List<String> populateWordList() {
    var config = new File("lib/src/resources/en-mnemonic-word-list.txt");
    List<String> lines = config.readAsLinesSync();
    return lines;
  }

  static void validateInitialEntropy(Uint8List initialEntropy) {
    if (initialEntropy == null) {
      throw new Exception("Initial entropy is required");
    }

    int ent = initialEntropy.length * 8;
    if (ent < 128 || ent > 256 || ent % 32 != 0) {
      throw new Exception(
          "The allowed size of ENT is 128-256 bits of " + "multiples of 32");
    }
  }

  static int calculateChecksum(Uint8List initialEntropy) {
    int ent = initialEntropy.length * 8;
    int mask = (0xff << 8 - ent ~/ 32);
    Uint8List bytes = new SHA256Digest().process(initialEntropy);

    return (bytes[0] & mask);
  }

  static List<bool> convertToBits(Uint8List initialEntropy, int checksum) {
    int ent = initialEntropy.length * 8;
    int checksumLength = ent ~/ 32;
    int totalLength = ent + checksumLength;
    List<bool> bits = new List(totalLength);

    for (int i = 0; i < initialEntropy.length; i++) {
      for (int j = 0; j < 8; j++) {
        int b = initialEntropy[i];
        bits[8 * i + j] = toBit(b, j);
      }
    }

    for (int i = 0; i < checksumLength; i++) {
      bits[ent + i] = toBit(checksum, i);
    }

    return bits;
  }

  static bool toBit(int value, int index) {
    return ((value >> (7 - index)) & 1) > 0;
  }

  static List<bool> nextElevenBits(List<bool> bits, int i) {
    int from = i * 11;
    int to = from + 11;
    var list = new List<bool>(11);
    List.copyRange(list, 0, bits, from, to);

    return list;
  }

  static int toInt(List<bool> bits) {
    int value = 0;
    for (int i = 0; i < bits.length; i++) {
      bool isSet = bits[i];
      if (isSet) {
        value += 1 << bits.length - i - 1;
      }
    }

    return value;
  }

  static void validateMnemonic(String mnemonic) {
    if (mnemonic == null || mnemonic.trim().isEmpty) {
      throw new Exception("Mnemonic is required to generate a seed");
    }
  }
}