part of bitcoin.script;

class ScriptChunk {
  /// Only set if opCode, otherwise null
  int opCode;

  /// Only set if not opcode, otherwise null
  Uint8List data;

  int startLocationInProgram;

  ScriptChunk.opCodeChunk(int this.opCode, [int this.startLocationInProgram]) {
    opCode = opCode & 0xff;
  }

  ScriptChunk.dataChunk(Uint8List this.data, [int this.startLocationInProgram]);

  bool get isOpCode => opCode != null;

  @override
  String toString() {
    if (isOpCode)
      return ScriptOpCodes.getOpCodeName(opCode);
    else
      return "[" + CryptoUtils.bytesToHex(data) + "]";
  }

  Uint8List serialize() {
    if (isOpCode) {
      return new Uint8List.fromList([opCode]);
    } else {
      return Script.encodeData(data);
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != ScriptChunk) return false;
    return isOpCode == other.isOpCode && utils.equalLists(serialize(), other.serialize());
  }

  @override
  int get hashCode => (isOpCode ? 0xffff : 0) ^ utils.listHashCode(serialize());
}
