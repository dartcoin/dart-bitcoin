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
  
  factory TransactionOutput.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) =>
      new BitcoinSerialization.deserialize(new TransactionOutput(), bytes, length: length, lazy: lazy);
  
  int get value {
    _needInstance();
    return _value;
  }
  
  Script get scriptPubKey {
    _needInstance();
    return _scriptPubKey;
  }
  
  Transaction get parent {
    return _parent;
  }
  
  int get index {
    if(_parent == null) throw new Exception("Parent tx not specified.");
    parent.outputs.indexOf(parent.outputs.singleWhere((output) => output == this));
  }
  
  @override
  operator ==(TransactionOutput other) {
    if(!(other is TransactionOutput)) return false;
    return value == other.value &&
        scriptPubKey == other.scriptPubKey &&
        (parent == null || other.parent == null || parent == other.parent);
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
  
  void _deserialize(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToUintBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.size;
    _scriptPubKey = null;//new Script.deserialize(bytes.sublist(offset), scrLn.value);
    offset += scrLn.value;
    _serializationLength = offset;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToUintBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.value;
  }
}