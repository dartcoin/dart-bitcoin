part of dartcoin.core;

class TransactionOutput extends Object with BitcoinSerialization {
  
  int _value;
  Script _scriptPubKey;
  
  Transaction _parent;
  
  TransactionOutput({ int value, 
                      Script scriptPubKey,
                      Transaction parent,
                      NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _value = value;
    _scriptPubKey = scriptPubKey;
    _parent = parent;
    this.params = params;
  }
  
  factory TransactionOutput.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) =>
      new BitcoinSerialization.deserialize(new TransactionOutput(), bytes, length: length, lazy: lazy, params: params);
  
  factory TransactionOutput.payToAddress(Address to, int amount, 
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToAddressOutputScript(to), parent: parent, params: params);
  }
  
  factory TransactionOutput.payToPubKey(KeyPair key, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToPubKeyOutputScript(key), parent: parent, params: params);
  }
  
  factory TransactionOutput.payToScriptHash(Uint8List scriptHash, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToScriptHash(scriptHash), parent: parent, params: params);
  }

  int get value {
    _needInstance();
    return _value;
  }
  
  Script get scriptPubKey {
    _needInstance();
    return _scriptPubKey;
  }
  
  Transaction get parentTransaction {
    return _parent;
  }
  
  void set parentTransaction(Transaction parentTransaction) {
    _parent = parentTransaction;
  }
  
  int get index {
    if(_parent == null) throw new Exception("Parent tx not specified.");
    _parent.outputs.indexOf(_parent.outputs.singleWhere((output) => output == this));
  }
  
  @override
  operator ==(TransactionOutput other) {
    if(!(other is TransactionOutput)) return false;
    return value == other.value &&
        scriptPubKey == other.scriptPubKey &&
        (parentTransaction == null || other.parentTransaction == null || parentTransaction == other.parentTransaction);
  }
  
  //TODO hashcode?
  
  Uint8List _serialize() {
    Uint8List encodedScript = scriptPubKey.encode();
    List<int> result = new List()
      ..addAll(Utils.uintToBytesBE(value, 8))
      ..addAll(new VarInt(encodedScript.length).serialize())
      ..addAll(scriptPubKey.encode());
    return new Uint8List.fromList(result);
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToUintBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.size;
    _scriptPubKey = null;//new Script.deserialize(bytes.sublist(offset), scrLn.value);
    offset += scrLn.value;
    return offset;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToUintBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.value;
  }
}