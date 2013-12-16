part of dartcoin;

class Transaction extends Object with BitcoinSerialization {
  
  Sha256Hash _hash;
  
  int _version = 0x01000000;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  int _lockTime;
  
  
  Transaction({ Sha256Hash txid,
                List<TransactionInput> inputs, 
                List<TransactionOutput> outputs,
                int lockTime}) {
    _hash = txid;
    _inputs = inputs;
    _outputs = outputs;
    _lockTime = lockTime;
  }
  
  factory Transaction.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
        new BitcoinSerialization.deserialize(new Transaction(), bytes, length: length, lazy: lazy);
  
  int get version {
    _needInstance();
    _version;
  }
  
  List<TransactionInput> get inputs {
    _needInstance();
    return _inputs;
  }
  
  List<TransactionOutput> get outputs {
    _needInstance();
    return _outputs;
  }
  
  int get lockTime {
    _needInstance();
    return _lockTime;
  }
  
  Sha256Hash get hash {
    if(_hash == null) {
      _calculateHash();
    }
    return _hash;
  }
  
  Sha256Hash get txid {
    return hash;
  }
  
  int get amount {
    _needInstance();
    int totalAmount = 0;
    try {
      for(TransactionInput input in inputs) {
        Transaction from = input.outpoint.transaction;
        TransactionOutput output = from.outputs[input.outpoint.index];
        totalAmount += output.value;
      }
    }
    on NoSuchMethodError catch(e) {
      throw new Exception("Not all inputs fully known. Unable to calculate total amount.");
    }
  }
  
  int get fee {
    _needInstance();
    int totalIn = amount;
    int totalOut = 0;
    try {
      for(TransactionOutput output in outputs) {
        totalOut += output.value;
      }
    }
    on NoSuchMethodError catch(e) {
      throw new Exception("Not all outputs fully known. Unable to calculate fee.");
    }
    return totalIn - totalOut;
  }
  
  void _calculateHash() {
    _hash = Sha256Hash.doubleDigest(serialize());
  }
  
  Uint8List _serialize() {
    List<int> result = new List();
    result.addAll(Utils.intToBytesBE(version, 4));
    result.addAll(new VarInt(inputs.length).serialize());
    for(TransactionInput input in inputs) {
      result.addAll(input.serialize());
    }
    result.addAll(new VarInt(outputs.length).serialize());
    for(TransactionInput output in outputs) {
      result.addAll(output.serialize());
    }
    result.addAll(Utils.intToBytesBE(lockTime, 4));
    return new Uint8List.fromList(result);
  }
  
  void _deserialize(Uint8List bytes) {
    int offset = 0;
    _version = Utils.bytesToIntBE(bytes.sublist(0), 4);
    offset += 4;
    _inputs = new List<TransactionInput>();
    VarInt nbInputs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbInputs.serializationLength;
    for(int i = 0 ; i < nbInputs.value ; i++) {
      TransactionInput input = new TransactionInput.deserialize(bytes.sublist(offset));
      offset += input.serializationLength;
      _inputs.add(input);
    }
    _outputs = new List<TransactionOutput>();
    VarInt nbOutputs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbOutputs.serializationLength;
    for(int i = 0 ; i < nbOutputs.value ; i++) {
      TransactionOutput output = new TransactionOutput.deserialize(bytes.sublist(offset));
      offset += output.serializationLength;
      _outputs.add(output);
    }
    _lockTime = Utils.bytesToIntBE(bytes.sublist(offset), 4);
    offset += 4;
    _serializationLength = offset;
  }
}








