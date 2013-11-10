part of dartcoin;

class TransactionInput {
  
  TransactionOutPoint outpoint;
  int scriptLength; //TODO maybe store in Script class?
  Script sigScript;
  int sequence;
  
  TransactionInput({TransactionOutPoint this.outpoint, 
                    int this.scriptLength: null,
                    Script this.sigScript,
                    int this.sequence: 0}) {
    if(scriptLength == null) {
      //TODO calculate scriptLength
    }
  }
  
  List<int> encode() {
    List<int> result = new List();
    result.addAll(outpoint.encode());
    result.addAll(new VarInt(scriptLength).encode());
    result.addAll(script.encode());
    result.addAll(Utils.intToBytesBE(sequence, 4));
    return result;
  }
}