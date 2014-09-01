part of dartcoin.core;

class TransactionOutput extends Object with BitcoinSerialization {
  
  int _value;
  Script _scriptPubKey;
  
  TransactionOutput({ int value, 
                      Script scriptPubKey,
                      Transaction parent,
                      NetworkParameters params: NetworkParameters.MAIN_NET}) {
    if(value < -1 || value > NetworkParameters.MAX_MONEY)
      throw new ArgumentError("Amounts must be positive and smaller than the max value.");
    _value = value;
    _scriptPubKey = scriptPubKey;
    _parent = parent;
    this.params = params;
  }
  
  // required for serialization
  TransactionOutput._newInstance();
  
  factory TransactionOutput.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) =>
      new BitcoinSerialization.deserialize(new TransactionOutput._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, parent: parent);
  
  factory TransactionOutput.payToAddress(Address to, int amount, 
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToPubKeyHashOutputScript.withAddress(to), parent: parent, params: params);
  }
  
  factory TransactionOutput.payToPubKey(KeyPair key, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToPubKeyOutputScript(key), parent: parent, params: params);
  }
  
  factory TransactionOutput.payToScriptHash(Uint8List scriptHash, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToScriptHashOutputScript(scriptHash), parent: parent, params: params);
  }

  int get value {
    _needInstance();
    return _value;
  }
  
  void set value(int value) {
    if(value < -1 || value > NetworkParameters.MAX_MONEY)
      throw new ArgumentError("Amounts must be positive and smaller than the max value.");
    _needInstance(true);
    _value = value;
  }
  
  Script get scriptPubKey {
    _needInstance();
    return _scriptPubKey;
  }
  
  void set scriptPubKey(Script scriptPubKey) {
    _needInstance(true);
    _scriptPubKey = scriptPubKey;
  }
  
  Transaction get parentTransaction => _parent as Transaction;
  
  void set parentTransaction(Transaction parentTransaction) {
    _parent = parentTransaction;
  }
  
  int get index {
    if(_parent == null || _parent is! Transaction) throw new Exception("Parent tx not specified.");
    return parentTransaction.outputs.indexOf(parentTransaction.outputs.singleWhere((output) => output == this));
  }
  
  @override
  operator ==(TransactionOutput other) {
    if(other is! TransactionOutput) return false;
    if(identical(this, other)) return true;
    _needInstance();
    other._needInstance();
    return _value == other._value &&
        _scriptPubKey == other._scriptPubKey;
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _value.hashCode ^ _scriptPubKey.hashCode;
  }

  @override
  void _serialize(ByteSink sink) {
    _writeUintLE(sink, _value, 8);
    _writeByteArray(sink, _scriptPubKey.encode());
  }

  @override
  void _deserialize() {
    _value = _readUintLE(8);
    _scriptPubKey = new Script(_readByteArray());
  }
  
  @override
  void _deserializeLazy() {
    _serializationCursor += 8;
    int scrLn = _readVarInt();
    _serializationCursor += scrLn;
  }
}