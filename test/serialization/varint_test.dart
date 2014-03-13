library dartcoin.test.serialization.varint;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "dart:typed_data";



void _testBytes() {
  VarInt a = new VarInt(10);
  expect(a.size, equals(1));
  expect(a.serializationLength, equals(1));
  expect(a.serialize().length, equals(1));
  expect(new VarInt.deserialize(a.serialize()).value, equals(10));
}

void _testShorts() {
  VarInt a = new VarInt(64000);
  expect(a.size, equals(3));
  expect(a.serializationLength, equals(3));
  expect(a.serialize().length, equals(3));
  expect(new VarInt.deserialize(a.serialize()).value, equals(64000));
}

void _testInts() {
  VarInt a = new VarInt(0xAABBCCDD);
  expect(a.size, equals(5));
  expect(a.serializationLength, equals(5));
  expect(a.serialize().length, equals(5));
  Uint8List bytes = a.serialize();
  expect(0xFFFFFFFF & new VarInt.deserialize(bytes).value, equals(0xAABBCCDD));
}

void _testLong() {
  VarInt a = new VarInt(0xCAFEBABEDEADBEEF);
  expect(a.size, equals(9));
  expect(a.serializationLength, equals(9));
  expect(a.serialize().length, equals(9));
  Uint8List bytes = a.serialize();
  expect(new VarInt.deserialize(bytes).value, equals(0xCAFEBABEDEADBEEF));
}

void main(){
  group("serialization.VarInt", () {
    test("varint_byte", () => _testBytes());
    test("varint_short", () => _testShorts());
    test("varint_int", () => _testInts());
    test("varint_long", () => _testLong());
  });
}