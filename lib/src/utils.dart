library bitcoin.src.utils;

import "dart:convert";
import "dart:math";
import "dart:typed_data";

import 'package:bitcoin/core.dart';
import "package:bytes/bytes.dart" as bytes;
import "package:collection/collection.dart";
import 'package:convert/convert.dart';
import "package:cryptoutils/cryptoutils.dart";

import "package:bitcoin/src/wire/serialization.dart";

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/src/utils.dart' as p_utils;

export "package:base58check/base58check.dart" show Base58CheckPayload;

/**
 * Currently unused, but can be used to replace all occurences of
 * - Uint8List.sublist()
 * - new Uint8List.fromList()
 *
 * These methods copy over while that may not always be necessary.
 *
 * TODO consider using this method
 */
Uint8List toBytes(List<int> bytes, [int start = 0, int end = -1]) {
  if (bytes == null) return null;
  if (end == -1) end = bytes.length;
  if (bytes is Uint8List) {
    return new Uint8List.view(bytes.buffer, start, end - start);
  }
  if (start == 0 && end == bytes.length) {
    return new Uint8List.fromList(bytes);
  }
  Uint8List result = new Uint8List(end - start);
  for (int i = 0; i < end - start; i++) {
    result[i] = bytes[start + i];
  }
  return result;
}


Uint8List utf8Encode(String string) {
  List<int> encoded = utf8.encode(string);
  return encoded is Uint8List ? encoded : new Uint8List.fromList(encoded);
}

String utf8Decode(Uint8List bytes) => utf8.decode(bytes);


const String _BYTE_ALPHABET = "0123456789ABCDEF";

//  bool isHexString(String maybeHexString) => HEX_REGEXP.hasMatch(maybeHexString);
bool isHexString(String hex) {
  hex = hex.replaceAll(" ", "");
  hex = hex.toUpperCase();
  for (int i = 0; i < hex.length; i++) {
    if (!_BYTE_ALPHABET.contains(hex[i])) return false;
  }
  return true;
}

Uint8List reverseBytes(Uint8List bytes) {
  if (bytes == null) return null;
  int length = bytes.length;
  Uint8List result = new Uint8List(length);
  for (int i = 0; i < length; i++) result[i] = bytes[length - 1 - i];
  return result;
}

Uint8List concatBytes(Uint8List bytes1, Uint8List bytes2) {
  Uint8List result = new Uint8List(bytes1.length + bytes2.length);
  result.setRange(0, bytes1.length, bytes1);
  result.setRange(bytes1.length, result.length, bytes2);
  return result;
}

/** The string that prefixes all text messages signed using Bitcoin keys. */
final String BITCOIN_SIGNED_MESSAGE_HEADER = "Bitcoin Signed Message:\n";
final Uint8List BITCOIN_SIGNED_MESSAGE_HEADER_BYTES =
    new Uint8List.fromList(new Utf8Encoder().convert(BITCOIN_SIGNED_MESSAGE_HEADER));

/**
 * <p>Given a textual message, returns a byte buffer formatted as follows:</p>
 *
 * <tt><p>[24] "Bitcoin Signed Message:\n" [message.length as a varint] message</p></tt>
 */
Uint8List formatMessageForSigning(String message) {
  var buffer = new bytes.Buffer();
  buffer.addByte(BITCOIN_SIGNED_MESSAGE_HEADER_BYTES.length);
  buffer.add(BITCOIN_SIGNED_MESSAGE_HEADER_BYTES);
  Uint8List messageBytes = new Utf8Encoder().convert(message);
  writeVarInt(buffer, new BigInt.from(messageBytes.length));
  buffer.add(messageBytes);
  return buffer.asBytes();
}

/**
 * Mimics Java's System.arraycopy() method.
 *
 * Uint8List.replaceRange doesn't work.
 */
void arrayCopy(Uint8List src, int srcPos, Uint8List dest, int destPos, [int length]) {
  length = length != null ? length : src.length;
  if (srcPos + length > src.length || destPos + length > dest.length)
    throw new ArgumentError("Invalid arguments: will cause overflow");
  for (int i = 0; i < length; i++) dest[destPos + i] = src[srcPos + i];
}

/**
 * Compare two lists, returns true if lists contain the same elements.
 *
 * "==" operator is used to compare the elements in the lists.
 */
bool equalLists(List list1, List list2) =>
    new ListEquality(new DefaultEquality()).equals(list1, list2);

/**
 * Generate a valid hashcode for the list.
 */
int listHashCode(List<int> list) => new ListEquality().hash(list);


/// Returns a position of the [value] in [sortedList], if it is there.
///
/// If the list isn't sorted according to the [compare] function, the result
/// is unpredictable.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. If any object is not [Comparable], this throws a [CastError].
///
/// Returns -1 if [value] is not in the list by default.
int binarySearch<T>(List<T> sortedList, T value, {int compare(T a, T b)}) {
  compare ??= (value1, value2) => (value1 as Comparable).compareTo(value2);
  int min = 0;
  int max = sortedList.length;
  while (min < max) {
    int mid = min + ((max - min) >> 1);
    var element = sortedList[mid];
    int comp = compare(element, value);
    if (comp == 0) return mid;
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

/**
 * The regular BigInt.toByteArray() method isn't quite what we often need:
 * it appends a leading zero to indicate that the number is positive and may
 * need padding.
 */
Uint8List BigIntToBytes(BigInt b, int numBytes) {
  if (b == null) {
    return null;
  }
  Uint8List bytes = new Uint8List(numBytes);
  Uint8List biBytes = new Uint8List.fromList(CryptoUtils.bigIntToByteArray(b));
  int start = (biBytes.length == numBytes + 1) ? 1 : 0;
  int length = min(biBytes.length, numBytes);
  bytes.setRange(numBytes - length, numBytes, biBytes.sublist(start, start + length));
  return bytes;
}

/**
 * Converts the integer to a byte array in little endian. Ony positive integers allowed.
 */
Uint8List uintToBytesLE(int val, [int size = -1]) {
  if (val < 0) throw new Exception("Only positive values allowed.");
  List<int> result = new List();
  while (val > 0) {
    int mod = val & 0xff;
    val = val >> 8;
    result.add(mod);
  }
  if (size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
  while (result.length < size) result.add(0);
  return new Uint8List.fromList(result);
}


/**
 * Converts the integer to a byte array in little endian. Ony positive integers allowed.
 */
Uint8List bigIntToBytesLE(BigInt val, [int size = -1]) {
  if (val.sign < 0) throw new Exception("Only positive values allowed.");
  List<int> result = new List();
  BigInt xff = new BigInt.from(0xff);
  while (val.sign > 0) {
    BigInt mod = val & xff;
    val = val >> 8;
    result.add(mod.toInt());
  }
  if (size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
  while (result.length < size) result.add(0);
  return new Uint8List.fromList(result);
}

/**
 * Converts the integer to a byte array in big endian. Ony positive integers allowed.
 */
Uint8List uintToBytesBE(int val, [int size = -1]) {
  if (val < 0) throw new ArgumentError("Only positive values allowed.");
  List<int> result = new List();
  while (val > 0) {
    int mod = val & 0xff;
    val = val >> 8;
    result.insert(0, mod);
  }
  if (size >= 0 && result.length > size)
    throw new ArgumentError("Value doesn't fit in given size.");
  while (result.length < size) result.insert(0, 0);
  return new Uint8List.fromList(result);
}

/**
 * Converts the [BigInt] to a byte array in little endian.
 */
Uint8List uBigIntToBytesLE(BigInt val, [int size = -1]) {
  List<int> bytes = CryptoUtils.bigIntToByteArray(val);
  if (bytes.length > size && size >= 0) {
    throw new Exception("Input too large to encode into a uint64");
  }
  bytes = new List.from(bytes.reversed);
  if (bytes.length < size) {
    while (bytes.length < size) bytes.add(0);
  }
  return new Uint8List.fromList(bytes);
}

/**
 * Converts the byte array to a [BigInt] in little endian.
 */
BigInt bytesToUBigIntLE(Uint8List bytes, [int size = -1]) {
  if (size < 0) size = bytes.length;
  return bytesToBigInt(reverseBytes(bytes.sublist(0, size)));
}

/**
 * Converts the big endian byte array to an unsigned integer.
 */
int bytesToUintBE(Uint8List bytes, [int size]) {
  if (size == null) size = bytes.length;
  int result = 0;
  for (int i = 0; i < size; i++) {
    result += bytes[i] << (8 * (size - i - 1));
  }
  return result;
}

/**
 * Converts the little endian byte array to an unsigned integer.
 */
int bytesToUintLE(Uint8List bytes, [int size]) {
  if (size == null) size = bytes.length;
  int result = 0;
  for (int i = 0; i < size; i++) {
    result += bytes[i] << (8 * i);
  }
  return result;
}


/**
 * Converts the little endian byte array to a BigInt.
 */
BigInt bytesToBigInt(Uint8List bytes, [int size]) {
  if (size == null) size = bytes.length;
  BigInt result = BigInt.zero;
  for (int i = 0; i < size; i++) {
    result += new BigInt.from(bytes[i]) << (8 * i);
  }
  return result;
}

/**
 * Converts the BE endian two's complement encoded bytes to an integer.
 *
 * Size in number of bytes, not bits;
 */
//TODO not a quite satisfactory implementation
int bytesTo2CInt(Uint8List bytes, [int size]) {
  if (size == null) size = bytes.length;
  int result = bytesToUintBE(bytes, size);
  if (bytes[0] >= 0x40) {
    // number is negative
    result = result - pow(2, 8 * size);
  }
  return result;
}

//  /**
//   * Encodes the [InternetAddress] to bytes.
//   *
//   * [address] can be a IPv4 or IPv6 address.
//   */
//  Uint8List encodeInternetAddressAsIPv6(    address) {
//    if(address.type == InternetAddressType.IP_V6)
//      return new Uint8List.fromList(Uri.parseIPv6Address(address.address));
//    return new Uint8List(16)
//      ..setRange(12, 16, Uri.parseIPv4Address(address.address))
//      ..[10] = 0xFF
//      ..[11] = 0xFF;
//  }
//
//  String _zeroPad(String toPad, int size) {
//    return new List.filled(size - toPad.length, "0").join() + toPad;
//  }
//
//  /**
//   * Decode the bytes to an [InternetAddress].
//   */
//  InternetAddress decodeInternetAddressAsIPv6(Uint8List bytes) {
//    if(bytes.length != 16) throw new FormatException("illegal format");
//    String address = "";
//    for(int i = 0 ; i < 8 ; i++) {
//      if(i != 0) address += ":";
//      address += CryptoUtils.bytesToHex(bytes.sublist(i * 2, i * 2 + 2));
//    }
//    return new InternetAddress(address);
//  }

/**
 * MPI encoded numbers are produced by the OpenSSL BN_bn2mpi function. They consist of
 * a 4 byte big endian length field, followed by the stated number of bytes representing
 * the number in big endian format (with a sign bit).
 * @param hasLength can be set to false if the given array is missing the 4 byte length field
 */
BigInt decodeMPI(Uint8List mpi, bool hasLength) {
  Uint8List buf;
  if (hasLength) {
    int length = bytesToUintBE(mpi, 4);
    if (mpi.length != 4 + length) throw new FormatException("Malformed MPI encoded integer");
    buf = mpi.sublist(4);
  } else {
    buf = mpi;
  }
  if (buf.length == 0) return BigInt.zero;
  bool isNegative = (buf[0] & 0x80) == 0x80;
  if (isNegative) buf[0] &= 0x7f;
  BigInt result = CryptoUtils.bigIntFromByteArray(buf);
  return isNegative ? -result : result;
}

/**
 * MPI encoded numbers are produced by the OpenSSL BN_bn2mpi function. They consist of
 * a 4 byte big endian length field, followed by the stated number of bytes representing
 * the number in big endian format (with a sign bit).
 * @param includeLength indicates whether the 4 byte length field should be included
 */
Uint8List encodeMPI(BigInt value, bool includeLength) {
  if (value == BigInt.zero) {
    if (!includeLength)
      return new Uint8List(0);
    else
      return new Uint8List(4);
  }
  bool isNegative = value < BigInt.zero;
  if (isNegative) value = -value;
  List<int> array = CryptoUtils.bigIntToByteArray(value);
  int length = array.length;
  if ((array[0] & 0x80) == 0x80) length++;
  if (includeLength) {
    Uint8List result = new Uint8List(length + 4);
    result.setRange(length - array.length + 3, length + 3, array);
    result.setRange(0, 4, uintToBytesBE(length, 4));
    if (isNegative) result[4] |= 0x80;
    return result;
  } else {
    Uint8List result;
    if (length != array.length) {
      result = new Uint8List(length);
      result.setRange(1, array.length + 1, array);
    } else {
      result = new Uint8List.fromList(array);
    }
    if (isNegative) result[0] |= 0x80;
    return result;
  }
}

// The representation of nBits uses another home-brew encoding, as a way to represent a large
// hash value in only 32 bits.
BigInt decodeCompactBits(int compact) {
//  int size = (compact >> 24) & 0xFF;
  int size = compact >> 24;
  Uint8List bytes = new Uint8List(4 + size);
  bytes[3] = size;
  if (size >= 1) bytes[4] = (compact >> 16) & 0xFF;
  if (size >= 2) bytes[5] = (compact >> 8) & 0xFF;
  if (size >= 3) bytes[6] = (compact >> 0) & 0xFF;
  return decodeMPI(bytes, true);
}

/**
 * Compute 32-bit logical shift right of a value. This emulates the Java >>> operator.
 */
int lsr(int n, int shift) {
  int shift5 = shift & 0x1f;
  int n32 = 0xffffffff & n;
  if (shift5 == 0)
    return n32;
  else
    return (n32 >> shift5) & ((0x7fffffff >> (shift5 - 1)));
}

/**
 * Checks if the given bit is set in data
 */
bool checkBitLE(Uint8List data, int index) {
  return (data[lsr(index, 3)] & _bitMask[7 & index]) != 0;
}

final Uint8List _bitMask = new Uint8List.fromList([0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]);

/**
 * Sets the given bit in data to one
 */
void setBitLE(Uint8List data, int index) {
  data[lsr(index, 3)] |= _bitMask[7 & index];
}


Uint8List intToByteArray(int data) {
  Uint8List result = new Uint8List(4);

  result[0] = ((data & 0xFF000000) >> 24);
  result[1] = ((data & 0x00FF0000) >> 16);
  result[2] = ((data & 0x0000FF00) >> 8);
  result[3] = ((data & 0x000000FF) >> 0);

  return result;
}

Uint8List hmacSha512(List<int> seed, List<int> passphraseByteArray) {
  var hmac = new HMac(new SHA512Digest(), 128);

  var rootSeed = new Uint8List(hmac.macSize);

  hmac.init(new KeyParameter(passphraseByteArray));

  hmac.update(seed, 0, seed.length);

  hmac.doFinal(rootSeed, 0);
  return rootSeed;
}

String getCompressedPubKey(String publicKey) {

  var curve_secp256k1 = new ECCurve_secp256k1();

  var ecPoint = curve_secp256k1.curve.decodePoint(hexToBytes(publicKey));

  if (ecPoint.y.toBigInteger().isEven) {

    return "02" + ecPoint.x.toBigInteger().toRadixString(16);

  } else if(ecPoint.y.toBigInteger().isOdd) {

    return "03" + ecPoint.x.toBigInteger().toRadixString(16);

  }
  return publicKey;
}

/// If present, removes the 0x from the start of a hex-string.
String strip0x(String hex) {
  if (hex.startsWith("0x"))
    return hex.substring(2);
  return hex;
}

/// Converts the [number], which can either be a dart [int] or a [BigInt],
/// into a hexadecimal representation. The number needs to be positive or zero.
///
/// When [pad] is set to true, this method will prefix a zero so that the result
/// will have an even length. Further, if [forcePadLen] is not null and the
/// result has a length smaller than [forcePadLen], the rest will be left-padded
/// with zeroes. Note that [forcePadLen] refers to the string length, meaning
/// that one byte has a length of 2. When [include0x] is set to true, the
/// output wil have "0x" prepended to it after any padding is done.
String toHex(dynamic number, {bool pad = false, bool include0x = false, int forcePadLen}) {
  String toHexSimple() {
    if (number is int)
      return number.toRadixString(16);
    else if (number is BigInt)
      return number.toRadixString(16);
    else
      throw new TypeError();
  }

  var hexString = toHexSimple();
  if (pad && !hexString.length.isEven)
    hexString = "0$hexString";
  if (forcePadLen != null)
    hexString = hexString.padLeft(forcePadLen, "0");
  if (include0x)
    hexString = "0x$hexString";

  return hexString;
}

/// Converts the [bytes] given as a list of integers into a hexadecimal
/// representation.
///
/// If any of the bytes is outside of the range [0, 256], the method will throw.
/// The outcome of this function will prefix a 0 if it would otherwise not be
/// of even length. If [include0x] is set, it will prefix "0x" to the hexadecimal
/// representation.
String bytesToHex(List<int> bytes, {bool include0x = false}) {
  return (include0x ? "0x" : "") + hex.encode(bytes);
}


/// Converts the given number, either a [int] or a [BigInt] to a list of
/// bytes representing the same value.
List<int> numberToBytes(dynamic number) {
  if (number is BigInt)
    return p_utils.encodeBigInt(number);

  var hexString = toHex(number, pad: true);
  return hex.decode(hexString);
}

/// Converts the hexadecimal string, which can be prefixed with 0x, to a byte
/// sequence.
List<int> hexToBytes(String hexStr) {
  return hex.decode(strip0x(hexStr));
}

///Converts the bytes from that list (big endian) to a BigInt.
BigInt bytesToInt(List<int> bytes) => p_utils.decodeBigInt(bytes);

List<int> intToBytes(BigInt number) => p_utils.encodeBigInt(number);

///Takes the hexadecimal input and creates a BigInt.
BigInt hexToInt(String hex) {
  return BigInt.parse(strip0x(hex), radix: 16);
}

/// Generates a public key for the given private key using the ecdsa curve which
/// Ethereum uses.
Uint8List privateKeyToPublic(Uint8List privateKey) {
  var privateKeyNum = bytesToInt(privateKey);
  var p = KeyPair.EC_PARAMS.G * privateKeyNum;

  //skip the type flag, https://github.com/ethereumjs/ethereumjs-util/blob/master/index.js#L319
  return p.getEncoded(false).sublist(1);
}
