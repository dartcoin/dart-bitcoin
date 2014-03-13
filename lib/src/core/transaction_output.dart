part of dartcoin.core;

class TransactionOutput extends Object with BitcoinSerialization {
  
  int _value;
  Script _scriptPubKey;
  
  TransactionOutput({ int value, 
                      Script scriptPubKey,
                      Transaction parent,
                      NetworkParameters params: NetworkParameters.MAIN_NET}) {
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
  
  Transaction get parentTransaction => _parent;
  
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
  
  Uint8List _serialize() {
    Uint8List encodedScript = _scriptPubKey.encode();
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesLE(_value, 8))
      ..addAll(new VarInt(encodedScript.length).serialize())
      ..addAll(encodedScript));
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _value = Utils.bytesToUintLE(bytes, 8);
    offset += 8;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.serializationLength;
    _scriptPubKey = new Script(bytes.sublist(offset, offset + scrLn.value));
    offset += scrLn.value;
    return offset;
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) => _calculateSerializationLength(bytes);
  
  static int _calculateSerializationLength(Uint8List bytes) {
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(8), lazy: false);
    return 8 + scrLn.serializationLength + scrLn.value;
    
  }
}