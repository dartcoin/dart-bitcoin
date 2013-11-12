part of dartcoin;

class TransactionOutPoint {
  
  Sha256Hash txid;
  int index;
  
  Transaction _tx;
  
  TransactionOutPoint({ Sha256Hash this.txid, 
                        int this.index,
                        Transaction transaction}) {
    _tx = transaction;
    txid = transaction.hash;
  }
  
  Transaction get transaction {
    if(_tx == null) {
      //TODO implement
    }
    return _tx;
  }
  
  void set transaction(Transaction transaction) {
    _tx = transaction;
    txid = transaction.hash;
  }
  
  Uint8List encode() {
    List<int> result = new List();
    result.addAll(txid.bytes);
    result.addAll(Utils.intToBytesBE(index, 4));
    return new Uint8List.fromList(result);
  }
}