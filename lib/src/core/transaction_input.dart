part of dartcoin.core;

class TransactionInput extends Object with BitcoinSerialization {
  
  TransactionOutPoint _outpoint;
  Script _scriptSig;
  int _sequence;
  
  TransactionInput({TransactionOutPoint outpoint, 
                    Script scriptSig,
                    int sequence: 0,
                    NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _outpoint = outpoint;
    _scriptSig = scriptSig;
    _sequence = sequence;
    this.params = params;
  }
  
  TransactionInput.coinbase() {
    _outpoint = new TransactionOutPoint(txid: Sha256Hash.ZERO_HASH, index: -1); //TODO verify
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
  
  bool get isCoinbase {
    _needInstance();
    return outpoint.txid == Sha256Hash.ZERO_HASH &&
        (outpoint.index & 0xFFFFFFFF) == 0xFFFFFFFF;
  }
  
  @override
  operator ==(TransactionInput other) {
    if(!(other is TransactionInput)) return false;
    return outpoint == other.outpoint &&
        scriptSig == other.scriptSig &&
        sequence == other.sequence;
  }
  
  //TODO hashcode
  
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