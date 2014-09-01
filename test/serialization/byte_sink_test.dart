library dartcoin.test.serialization.byte_sink;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "dart:typed_data";



void _test1() {
  ByteSink bs = new ByteSink(1);
  bs.add(new Uint8List.fromList([1,2,3]));
  expect(bs.size, equals(3));
  bs.add([4,5,6,7]);
  expect(bs.size, equals(7));
  bs.add(8);
  expect(bs.toUint8List(), equals([1,2,3,4,5,6,7,8]));
}

void _test2() {
  ByteSink bs = new ByteSink(1);
  bs.add([4,5,6,7]);
  expect(bs.size, equals(4));
  bs.add(new Uint8List.fromList([1,2,3]));
  bs.add(8);
  expect(bs.toUint8List(), equals([4,5,6,7,1,2,3,8]));
}

void main(){
  group("serialization.VarInt", () {
    test("byte_sink_1", () => _test1());
    test("byte_sink_2", () => _test2());
  });
}