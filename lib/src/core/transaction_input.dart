part of dartcoin.core;

class TransactionInput extends Object with BitcoinSerialization {
  
  static const int NO_SEQUENCE = 0xFFFFFFFF;
  
  TransactionOutPoint _outpoint;
  Script _scriptSig;
  int _sequence;
  
  /**
   * Create a new [TransactionInput].
   * 
   * It's not possible to specify both the [output] parameter and the [outpoint] parameter. 
   */
  TransactionInput({TransactionOutPoint outpoint,
                    Script scriptSig,
                    Transaction parent, 
                    int sequence: NO_SEQUENCE,
                    NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _outpoint = outpoint != null ? outpoint : new TransactionOutPoint(index: NO_SEQUENCE, params: params);
    _scriptSig = scriptSig != null ? scriptSig : Script.EMPTY_SCRIPT;
    _sequence = sequence;
    _parent = parent;
    this.params = params;
  }
  
  factory TransactionInput.fromOutput(TransactionOutput output, 
      {Transaction parentTransaction, NetworkParameters params}) {
    TransactionOutPoint outpoint = new TransactionOutPoint(transaction: output.parentTransaction, 
              index: output.index, params: output.params);
    return new TransactionInput(outpoint: outpoint, parent: parentTransaction, params: output.params);
  }
  
  /**
   * Create a coinbase transaction input. 
   * 
   * It is specified by its [TransactionOutPoint] format, but can carry any [Script] as [scriptSig].
   */
  TransactionInput.coinbase([Script scriptSig]) {
    _outpoint = new TransactionOutPoint(txid: Sha256Hash.ZERO_HASH, index: 0xFFFFFFFF); //TODO verify
    _scriptSig = (scriptSig != null) ? scriptSig : Script.EMPTY_SCRIPT;
  }
  
  // required for serialization
  TransactionInput._newInstance();
  
  factory TransactionInput.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) =>
      new BitcoinSerialization.deserialize(new TransactionInput._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, parent: parent);
  
  TransactionOutPoint get outpoint {
    _needInstance();
    return _outpoint;
  }
  
  void set outpoint(TransactionOutPoint outpoint) {
    _needInstance(true);
    _outpoint = outpoint;
  }
  
  Script get scriptSig {
    _needInstance();
    return _scriptSig;
  }
  
  void set scriptSig(Script scripSig) {
    _needInstance(true);
    _scriptSig = scripSig;
  }
  
  int get sequence {
    _needInstance();
    return _sequence;
  }
  
  void set sequence(int sequence) {
    _needInstance(true);
    _sequence = sequence;
  }
  
  Transaction get parentTransaction => _parent;
  
  void set parentTransaction(Transaction parentTransaction) {
    _parent = parentTransaction;
  }
  
  bool get isCoinbase {
    _needInstance();
    return _outpoint.txid == Sha256Hash.ZERO_HASH &&
        (_outpoint.index & 0xFFFFFFFF) == 0xFFFFFFFF;
  }
  
  @override
  operator ==(TransactionInput other) {
    if(other is! TransactionInput) return false;
    if(identical(this, other)) return true;
    _needInstance();
    other._needInstance();
    return _outpoint == other._outpoint &&
        _scriptSig == other._scriptSig &&
        _sequence == other._sequence;
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _outpoint.hashCode ^ _scriptSig.hashCode ^ _sequence.hashCode;
  }
  
  Uint8List _serialize() {
    Uint8List encodedScript = _scriptSig.encode();
    return new Uint8List.fromList(new List()
      ..addAll(_outpoint.serialize())
      ..addAll(new VarInt(encodedScript.length).serialize())
      ..addAll(encodedScript)
      ..addAll(Utils.uintToBytesLE(_sequence, 4)));
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _outpoint = new TransactionOutPoint.deserialize(bytes, lazy: lazy, retain: retain);
    offset += _outpoint.serializationLength;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.size;
    _scriptSig = new Script(bytes.sublist(offset, offset + scrLn.value));
    offset += scrLn.value;
    _sequence = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    offset += 4;
    return offset;
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) => _calculateSerializationLength(bytes);
  
  static int _calculateSerializationLength(Uint8List bytes) {
    int offset = TransactionOutPoint.SERIALIZATION_LENGTH;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.serializationLength + scrLn.value + 4;
  }
}

