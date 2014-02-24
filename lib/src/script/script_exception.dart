part of dartcoin.core;

class ScriptException implements Exception {
  
  final String message;
  final Script script;
  final int opcode;
  
  const ScriptException([String this.message, Script this.script, int this.opcode]);
  
  @override
  String toString() => message;
  
  @override
  bool operator ==(ScriptException other) => 
      other is ScriptException && 
      message == other.message && 
      script == other.script && 
      opcode == other.opcode;  
  
}