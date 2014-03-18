library dartcoin.test.hash.hash_representation;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";


Transaction tx;
Transaction fake;
Transaction fake2;

void _setUp() {
  tx = new Transaction(txid: Sha256Hash.ZERO_HASH);
  fake = new TransactionHash.from(tx);
  fake2 = new TransactionHash(Sha256Hash.ZERO_HASH);
}

void _testEquals() {
  expect(fake == tx, isTrue);
  expect(tx == fake, isTrue);
  expect(tx == fake2, isTrue);
  expect(fake2 == tx, isTrue);
  expect(fake.hashCode, equals(tx.hashCode));
  expect(fake2.hashCode, equals(tx.hashCode));
}

void _testIsHashOnly() {
  expect(tx.isHashOnly, isFalse);
  expect(fake.isHashOnly, isTrue);
}

void _testCasting() {
  expect(fake is Transaction, isTrue);
}

void _testMethodReplacer() {
  expect(fake.inputs, isNull);
  expect(fake2.serialize(), isNull);
}

void _testPlainHash() {
  HashRepresentation hash = new HashRepresentation.from(tx);
  
  expect(hash == tx, isTrue);
  expect(tx == hash, isTrue);
  expect(hash is Transaction, isFalse);
}

void main() {
  group("hash.HashRepresentation", () {
    setUp(() => _setUp());
    test("equals", () => _testEquals());
    test("isHashOnly", () => _testIsHashOnly());
    test("casting", () => _testCasting());
    test("methodReplacer", () => _testMethodReplacer());
    test("plain-hash", () => _testPlainHash());
  });
}