library dartcoin.test.serialization.varint;

import "package:bytes/bytes.dart";

import "package:test/test.dart";

import "package:dartcoin/src/wire/serialization.dart";

ReaderBuffer buffer;

void main() {
  group("serialization.VarInt", () {
    setUp(() {
      buffer = new ReaderBuffer();
    });

    test("varint_byte", () {
      writeVarInt(buffer, 10);
      expect(buffer.length, equals(1));
      expect(buffer.asBytes().length, equals(1));
      expect(readVarInt(buffer), equals(10));
    });

    test("varint_short", () {
      writeVarInt(buffer, 64000);
      expect(buffer.length, equals(3));
      expect(buffer.asBytes().length, equals(3));
      expect(readVarInt(buffer), equals(64000));
    });

    test("varint_int", () {
      writeVarInt(buffer, 0xAABBCCDD);
      expect(buffer.length, equals(5));
      expect(buffer.asBytes().length, equals(5));
      expect(readVarInt(buffer), equals(0xAABBCCDD));
    });

    test("varint_long", () {
      writeVarInt(buffer, 0xCAFEBABEDEADBEEF);
      expect(buffer.length, equals(9));
      expect(buffer.asBytes().length, equals(9));
      expect(readVarInt(buffer), equals(0xCAFEBABEDEADBEEF));
    });
  });
}
