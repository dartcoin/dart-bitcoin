part of dartcoin.wire;

class TxMessage extends Message {
  
  Transaction tx;
  
  TxMessage(Transaction this.tx) : super("tx");
  
  Uint8List encode_payload() {
    return tx.encode();
  }
}