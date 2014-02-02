part of dartcoin;

class TransactionOutput extends Object with BitcoinSerialization {
  
  int _value;
  Script _scriptPubKey;
  
  TransactionOutput({ int value, 
                      Script scriptPubKey}) {
    _value = value;
    _scriptPubKey = scriptPubKey;
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
    offset += scrLn.serializationLength;
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