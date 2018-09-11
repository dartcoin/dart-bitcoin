library bitcoin.wire.serialization;

import "dart:convert";
import "dart:typed_data";

import "package:bytes/bytes.dart" as bytes;
import "package:cryptoutils/cryptoutils.dart";

import "package:bitcoin/src/utils.dart" as utils;

/// This interface defines the minimal functions required to support Bitcoin serialization.
abstract class BitcoinSerializable {
  void bitcoinDeserialize(bytes.Reader reader, int pver);

  void bitcoinSerialize(bytes.Buffer buffer, int pver);

  Uint8List bitcoinSerializedBytes(int pver) {
    var buffer = new bytes.Buffer();
    bitcoinSerialize(buffer, pver);
    return buffer.asBytes();
  }
}

//TODO rename to BitcoinSerializationException
class SerializationException implements Exception {
  final String message;

  SerializationException([String this.message]);

  @override
  String toString() => "SerializationException: $message";

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != SerializationException) return false;
    return message == other.message;
  }
}

/////////////
// READING //
/////////////

Uint8List readBytes(bytes.Reader reader, int length) {
  return reader.readBytes(length);
}

BigInt readBigIntLE(bytes.Reader reader, [int length = 4]) {
  BigInt result = utils.bytesToBigInt(readBytes(reader, length), length);
  return result;
}

int readUintLE(bytes.Reader reader, [int length = 4]) {
  int result = utils.bytesToUintLE(readBytes(reader, length), length);
  return result;
}

/// In the Bitcoin protocol, hashes are serialized in little endian.
Hash256 readSHA256(bytes.Reader reader) {
  return new Hash256(utils.reverseBytes(readBytes(reader, 32)));
}

BigInt readVarInt(bytes.Reader reader) {
  BigInt firstByte = readBigIntLE(reader, 1);
  int intFirstByte = firstByte.toInt();
  if (intFirstByte == 0xfd) {
    return readBigIntLE(reader, 2);
  }
  if (intFirstByte == 0xfe) {
    return readBigIntLE(reader, 4);
  }
  if (intFirstByte == 0xff) {
    return readBigIntLE(reader, 8);//reader.length-1);
  }
  return firstByte;
}

Uint8List readByteArray(bytes.Reader reader) {
  BigInt size = readVarInt(reader);
  return readBytes(reader, size.toInt());
}

String readVarStr(bytes.Reader reader) {
  return utf8.decode(readByteArray(reader));
}

BitcoinSerializable readObject(
    bytes.Reader reader, BitcoinSerializable obj, int pver) {
  obj.bitcoinDeserialize(reader, pver);
  return obj;
}

/////////////
// WRITING //
/////////////

void writeBytes(bytes.Buffer buffer, List<int> bytes) {
  buffer.add(bytes);
}

void writeBigIntLE(bytes.Buffer buffer, BigInt value, [int length = 4]) {
  writeBytes(buffer, utils.bigIntToBytesLE(value, length));
}
void writeUintLE(bytes.Buffer buffer, int value, [int length = 4]) {
  writeBytes(buffer, utils.uintToBytesLE(value, length));
}

/// In the Bitcoin protocol, hashes are serialized in little endian.
void writeSHA256(bytes.Buffer buffer, Hash256 hash) {
  writeBytes(buffer, utils.reverseBytes(hash.asBytes()));
}

void writeVarInt(bytes.Buffer buffer, BigInt value) {
  int intValue = value.toInt();
  if (intValue < 0xfd) {
    writeBytes(buffer, [value.toInt()]);
  } else if (intValue <= 0xffff) {
    writeBytes(buffer, [0xfd]);
    writeBigIntLE(buffer, value, 2);
  } else if (intValue <= 0xffffffff) {
    writeBytes(buffer, [0xfe]);
    writeBigIntLE(buffer, value, 4);
  } else {
    writeBytes(buffer, [0xff]);
    writeBigIntLE(buffer, value, 8); // TODO 8+?
  }
}

void writeByteArray(bytes.Buffer buffer, Uint8List bytes) {
  writeVarInt(buffer, new BigInt.from(bytes.length));
  writeBytes(buffer, bytes);
}

void writeVarStr(bytes.Buffer buffer, String string) {
  writeByteArray(buffer, utf8.encode(string));
}

void writeObject(bytes.Buffer buffer, BitcoinSerializable obj, int pver) {
  obj.bitcoinSerialize(buffer, pver);
}
