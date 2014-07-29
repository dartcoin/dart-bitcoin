part of dartcoin.core;

/**
 * Intended to be used as superclass of classes that are hash representations 
 * of objects of another class.
 */
class HashRepresentation extends HashRepresentable {
  
  final Sha256Hash hash;
  
  HashRepresentation(Sha256Hash this.hash);
  HashRepresentation.from(HashRepresentable from) : this(from.hash);
  
  bool get isHashOnly => true;
  
  @override
  void noSuchMethod(Invocation invocation) => null;
}

class BlockHash extends HashRepresentation implements Block {
  BlockHash(Sha256Hash hash) : super(hash);
  BlockHash.from(Block block) : this(block.hash);
  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TransactionHash extends HashRepresentation implements Transaction {
  TransactionHash(Sha256Hash hash) : super(hash);
  TransactionHash.from(Transaction tx) : this(tx.hash);
  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}