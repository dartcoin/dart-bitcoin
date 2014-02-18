part of dartcoin.core;

class TransactionOutPoint extends Object with BitcoinSerialization {
  
  Sha256Hash _txid;
  int _index;
  
  Transaction _tx;
  
  TransactionOutPoint({ Sha256Hash txid, 
                        int index,
                        Transaction transaction,
                        NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _txid = txid;
    _index = index;
    _tx = transaction;
    if(transaction != null)
      txid = transaction.hash;
    this.params = params;
  }
  
  factory TransactionOutPoint.deserialize(Uint8List bytes, {bool lazy: true}) =>
      new BitcoinSerialization.deserialize(new TransactionOutPoint(), bytes, length: 36, lazy: lazy);
  
  Sha256Hash get txid {
    _needInstance();
    return _txid;
  }
  
  int get index {
    _needInstance();
    return _index;
  }
  
  Transaction get transaction {
    _needInstance();
    if(_tx == null) {
      //TODO implement or return null?
    }
    return _tx;
  }
  
  @override
  operator ==(TransactionOutPoint other) {
    if(!(other is TransactionOutPoint)) return false;
    return txid == other.txid &&
        index == other.index &&
        (transaction == null || other.transaction == null || transaction == other.transaction);
  }
  
  //TODO hashcode?
  
  Uint8List _serialize() {
    List<int> result = new List()
      ..addAll(txid.bytes)
      ..addAll(Utils.uintToBytesBE(index, 4));
    return new Uint8List.fromList(result);
  }
  
  void _deserialize(Uint8List bytes) {
    _txid = new Sha256Hash(bytes.sublist(0, 32));
    _index = Utils.bytesToUintBE(bytes.sublist(32), 4);
  }
  
  int _lazySerializationLength(Uint8List bytes) => 36;
}