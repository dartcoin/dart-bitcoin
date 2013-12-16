part of dartcoin;

class TransactionOutput extends Object with BitcoinSerialization {
  
  int _value;
  int _scriptLength; //TODO
  Script _scriptPubKey;
  
  TransactionOutput({ int value, 
                      int scriptLength,
                      Script scriptPubKey}) {
    _value = value;
    _scriptPubKey = scriptPubKey;
  }
  
  factory TransactionOutput.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) =>
      new BitcoinSerialization.deserialize(new TransactionOutput(), bytes, length: length, lazy: lazy);
  
  int get value{
    _needInstance();
    return _value;
  }
  
  int get scriptLength { //TODO needed?
    _needInstance();
    return _scriptLength;
  }
  
  Script get scriptPubKey {
    _needInstance();
    return _scriptPubKey;
  } 
  
  Uint8List _serialize() {
    List<int> result = new List();
    result.addAll(Utils.intToBytesBE(value, 8));
    result.addAll(new VarInt(scriptLength).serialize());
    result.addAll(scriptPubKey.encode());
    return new Uint8List.fromList(result);
  }
  
  void _deserialize(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToIntBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.serializationLength;
    _scriptPubKey = null;//new Script.deserialize(bytes.sublist(offset), scrLn.value);
    offset += scrLn.value;
    _serializationLength = offset;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int offset = 0;
    _value = Utils.bytesToIntBE(bytes, 4);
    offset += 4;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.value;
  }
}