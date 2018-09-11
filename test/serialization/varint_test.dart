library bitcoin.test.serialization.varint;

import "package:bytes/bytes.dart";

import "package:test/test.dart";

import "package:bitcoin/src/wire/serialization.dart";

ReaderBuffer buffer;

void main() {
  group("serialization.VarInt", () {
    setUp(() {
      buffer = new ReaderBuffer();
    });

    test("varint_byte", () {
      BigInt biOrg = new BigInt.from(10);
      writeVarInt(buffer, biOrg);
      expect(buffer.length, equals(1));
      expect(buffer.asBytes().length, equals(1));
      expect(readVarInt(buffer), equals(biOrg));
    });

    test("varint_short", () {
      BigInt biOrg = new BigInt.from(64000);
      writeVarInt(buffer, biOrg);
      expect(buffer.length, equals(3));
      expect(buffer.asBytes().length, equals(3));
      expect(readVarInt(buffer), equals(biOrg));
    });

    test("varint_int", () {
      BigInt biOrg = BigInt.parse("0xAABBCCDD");
      writeVarInt(buffer, biOrg);
      expect(buffer.length, equals(5));
      expect(buffer.asBytes().length, equals(5));
      expect(readVarInt(buffer), equals(biOrg));
    });

    test("varint_long", () {
      BigInt biOrg = BigInt.parse("0xCAFEBABEDEADBEEF");
      writeVarInt(buffer, biOrg);
      expect(buffer.length, equals(9));
      expect(buffer.asBytes().length, equals(9));
      expect(readVarInt(buffer), equals(biOrg));
    });
  });
}
