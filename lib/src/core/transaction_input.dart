part of dartcoin;

class TransactionInput extends Object with BitcoinSerialization {
  
  TransactionOutPoint _outpoint;
  Script _scriptSig;
  int _sequence;
  
  TransactionInput({TransactionOutPoint outpoint, 
                    Script scriptSig,
                    int sequence: 0}) {
    _outpoint = outpoint;
    _scriptSig = scriptSig;
    _sequence = sequence;
  }
  
  factory TransactionInput.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) =>
      new BitcoinSerialization.deserialize(new TransactionInput(), bytes, length: length, lazy: lazy);
  
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
  
  Uint8List _serialize() {
    Uint8List encodedScript = scriptSig.encode();
    List<int> result = new List()
      ..addAll(outpoint.serialize())
      ..addAll(new VarInt(encodedScript.length).serialize())
      ..addAll(scriptSig.encode())
      ..addAll(Utils.uintToBytesBE(sequence, 4));
    return new Uint8List.fromList(result);
  }
  
  void _deserialize(Uint8List bytes) {
    int offset = 0;
    _outpoint = new TransactionOutPoint.deserialize(bytes);
    offset += outpoint.serializationLength;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += scrLn.serializationLength;
    _scriptSig = null;//TODO new Script.deserialize(bytes.sublist(offset), scrLn.value);
    offset += scrLn.value;
    _sequence = Utils.bytesToUintBE(bytes.sublist(offset), 4);
    offset += 4;
    _serializationLength = offset;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int offset = 0;
    _outpoint = new TransactionOutPoint.deserialize(bytes);
    offset += outpoint.serializationLength;
    VarInt scrLn = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    return offset + scrLn.value + 4;
  }
}