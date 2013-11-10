part of dartcoin;

class TransactionOutput {
  
  int value;
  int scriptLength; //TODO maybe store in Script class
  Script pkScript;
  
  TransactionOutput({ int this.value, 
                      int this.scriptLength,
                      Script this.pkScript}) {
    if(scriptLength == null) {
      //TODO calculate scriptlength
    }
  }
  
  List<int> encode() {
    List<int> result = new List();
    result.addAll(Utils.intToBytesBE(value, 8));
    result.addAll(new VarInt(scriptLength).encode());
    result.addAll(pkScript.encode());
    return result;
  }
}