part of dartcoin;

class TransactionOutput {
  
  int value;
  int scriptLength; //TODO maybe store in Script class
  Script scriptPubKey;
  
  TransactionOutput({ int this.value, 
                      int this.scriptLength,
                      Script this.scriptPubKey}) {
    if(scriptLength == null) {
      //TODO calculate scriptlength
    }
  }
  
  Uint8List encode() {
    Uint8List result = new List();
    result.addAll(Utils.intToBytesBE(value, 8));
    result.addAll(new VarInt(scriptLength).encode());
    result.addAll(scriptPubKey.encode());
    return result;
  }
}