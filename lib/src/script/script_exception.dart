part of bitcoin.script;

class ScriptException extends VerificationException {
  //TODO

  final Script script;
  final int opcode;

  ScriptException([String message, Script this.script, int this.opcode])
      : super(message);

  @override
  String toString() => "ScriptException: $message";

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType == ScriptException) return false;
    return message == other.message &&
        script == other.script &&
        opcode == other.opcode;
  }
}
