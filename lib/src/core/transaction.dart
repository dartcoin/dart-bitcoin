part of dartcoin;

class Transaction {
  
  Sha256Hash _hash;
  
  final int version = 0x01000000;
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
  
  List<TransactionInput> get inputs {
    return _inputs;
  }
  
  void set inputs(List<TransactionInput> inputs) {
    _inputs = inputs;
    _hash = null;
  }
  
  List<TransactionOutput> get outputs {
    return _outputs;
  }
  
  void set outputs(List<TransactionOutput> outputs) {
    _outputs = outputs;
    _hash = null;
  }
  
  int get lockTime {
    return _lockTime;
  }
  
  void set lockTime(int lockTime) {
    _lockTime = lockTime;
    _hash = null;
  }
  
  Sha256Hash get hash {
    if(_hash == null) {
      _calculateHash();
    }
    return _hash;
  }
  
  void set hash(Sha256Hash hash) {
    _hash = txid;
  }
  
  Sha256Hash get txid {
    return hash;
  }
  
  void set txid(Sha256Hash txid) {
    hash = txid;
  }
  
  int get amount {
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
    _hash = Sha256Hash.createDouble(encode());
  }
  
  Uint8List encode() {
    List<int> result = new List();
    result.addAll(Utils.intToBytesBE(version, 4));
    result.addAll(new VarInt(inputs.length).encode());
    for(TransactionInput input in inputs) {
      result.addAll(input.encode());
    }
    result.addAll(new VarInt(outputs.length).encode());
    for(TransactionInput output in outputs) {
      result.addAll(output.encode());
    }
    result.addAll(Utils.intToBytesBE(lockTime, 4));
    return new Uint8List.fromList(result);
  }
}








