part of dartcoin.core;

class TransactionOutPoint extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_LENGTH = 36;

  Hash256 _txid;
  int _index;
  
  Transaction _tx;
  
  TransactionOutPoint({ Transaction transaction, 
                        int index: 0,
                      Hash256 txid,
                        NetworkParameters params: NetworkParameters.MAIN_NET}) {
    if(transaction != null)
      txid = transaction.hash;
    if(index == -1)
      index = 0xFFFFFFFF;
    _index = index;
    _txid = txid != null ? txid : Hash256.ZERO_HASH;
    _tx = transaction;
    this.params = params;
    _serializationLength = SERIALIZATION_LENGTH;
  }
  
  // required for serialization
  TransactionOutPoint._newInstance();
  
  factory TransactionOutPoint.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params}) =>
      new BitcoinSerialization.deserialize(new TransactionOutPoint._newInstance(), bytes, length: SERIALIZATION_LENGTH, lazy: lazy, retain: retain, params: params);

  Hash256 get txid {
    _needInstance();
    return _txid;
  }

  void set txid(Hash256 txid) {
    _needInstance(true);
    _txid = txid;
    _tx = null;
  }
  
  int get index {
    _needInstance();
    return _index;
  }

  void set index(int index) {
    _needInstance(true);
    _index = index & 0xffffffff;
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

  @override
  void _serialize(ByteSink sink) {
    _writeSHA256(sink, _txid);
    _writeUintLE(sink, _index);
  }

  @override
  void _deserialize() {
    _txid = _readSHA256();
    _index = _readUintLE();
  }

  @override
  void _deserializeLazy() {
    _serializationCursor += 32 + 4;
  }
}