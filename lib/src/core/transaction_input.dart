part of dartcoin.core;

class TransactionInput extends Object with BitcoinSerialization {
  
  static const int NO_SEQUENCE = 0xFFFFFFFF;
  
  TransactionOutPoint _outpoint;
  Script _scriptSig;
  int _sequence;
  
  Transaction _parent;
  
  /**
   * Create a new [TransactionInput].
   * 
   * It's not possible to specify both the [output] parameter and the [outpoint] parameter. 
   */
  TransactionInput({TransactionOutput output, 
                    Script scriptSig,
                    TransactionOutPoint outpoint,
                    int sequence: NO_SEQUENCE,
                    Transaction parentTransaction, 
                    NetworkParameters params: NetworkParameters.MAIN_NET}) {
    if(output != null) {
      if(outpoint != null)
        throw new Exception("It's not possible to specify both the output parameter and the outpoint + sequence parameter.");
      outpoint = new TransactionOutPoint(transaction: output.parentTransaction, index: output.index, params: params);
    }
    _outpoint = outpoint;
    _scriptSig = scriptSig;
    _sequence = sequence;
    _parent = parentTransaction;
    this.params = params;
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
  
  factory TransactionInput.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) =>
      new BitcoinSerialization.deserialize(new TransactionInput(), bytes, length: length, lazy: lazy, params: params);
  
  TransactionOutPoint get outpoint {
    _needInstance();
    return _outpoint;
  }
  
  Script get scriptSig {
    _needInstance();
    return _scriptSig;
  }
  
  int get sequence {
    _needInstance();
    return _sequence;
  }
  
  Transaction get parentTransaction {
    return _parent;
  }
  
  void set parentTransaction(Transaction parentTransaction) {
    _parent = parentTransaction;
  }
  
  bool get isCoinbase {
    _needInstance();
    return outpoint.txid == Sha256Hash.ZERO_HASH &&
        (outpoint.index & 0xFFFFFFFF) == 0xFFFFFFFF;
  }
  
  @override
  operator ==(TransactionInput other) {
    if(!(other is TransactionInput)) return false;
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
      ..addAll(Utils.uintToBytesBE(_sequence, 4)));
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    _outpoint = new TransactionOutPoint.deserialize(bytes);
    offset += outpoint.serializationLength;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.size;
    _scriptSig = new Script(bytes.sublist(offset, offset + scrLn.value));
    offset += scrLn.value;
    _sequence = Utils.bytesToUintBE(bytes.sublist(offset), 4);
    offset += 4;
    return offset;
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) {
    int offset = TransactionOutPoint.SERIALIZATION_LENGTH;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.value + 4;
  }
}