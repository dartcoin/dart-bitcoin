part of dartcoin.script;

class ScriptException extends VerificationException {//TODO

  final Script script;
  final int opcode;
  
  ScriptException([String message, Script this.script, int this.opcode]) : super(message);
  
  @override
  String toString() => "ScriptException: $message";
  
  @override
  bool operator ==(ScriptException other) => 
      other is ScriptException && 
      message == other.message && 
      script == other.script && 
      opcode == other.opcode;  
  
}