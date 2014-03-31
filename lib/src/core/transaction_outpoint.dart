part of dartcoin.core;

class TransactionOutPoint extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_LENGTH = 36;
  
  Sha256Hash _txid;
  int _index;
  
  Transaction _tx;
  
  TransactionOutPoint({ Transaction transaction, 
                        int index: 0,
                        Sha256Hash txid,
                        NetworkParameters params: NetworkParameters.MAIN_NET}) {
    if(transaction != null)
      txid = transaction.hash;
    if(index == -1)
      index = 0xFFFFFFFF;
    _index = index;
    _txid = txid != null ? txid : Sha256Hash.ZERO_HASH;
    _tx = transaction;
    this.params = params;
    _serializationLength = SERIALIZATION_LENGTH;
  }
  
  // required for serialization
  TransactionOutPoint._newInstance();
  
  factory TransactionOutPoint.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params}) =>
      new BitcoinSerialization.deserialize(new TransactionOutPoint._newInstance(), bytes, length: SERIALIZATION_LENGTH, lazy: lazy, retain: retain, params: params);
  
  Sha256Hash get txid {
    _needInstance();
    return _txid;
  }
  
  int get index {
    _needInstance();
    return _index;
  }
  
  /**
   * Can be `null` when this object has been created by deserialization.
   */
  Transaction get transaction => _tx;
  
  TransactionOutput get connectedOutput {
    if(_tx == null) return null;
    return _tx.outputs[index];
  }
  
  @override
  operator ==(TransactionOutPoint other) {
    if(other is! TransactionOutPoint) return false;
    if(identical(this, other)) return true;
    _needInstance();
    other._needInstance();
    return _txid == other._txid &&
        _index == other._index &&
        (_tx == null || other._tx == null || _tx == other._tx);
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _index.hashCode ^ _txid.hashCode;
  }
  
  Uint8List _serialize() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(_txid.serialize())
      ..addAll(Utils.uintToBytesLE(_index, 4)));
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    _txid = new Sha256Hash.deserialize(bytes.sublist(0, 32));
    _index = Utils.bytesToUintLE(bytes.sublist(32), 4);
    return SERIALIZATION_LENGTH;
  }
}