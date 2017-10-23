part of bitcoin.script;

class Script {
  static final int MAX_SCRIPT_ELEMENT_SIZE = 520; //bytes
  static final Script EMPTY_SCRIPT = new Script(new Uint8List(0));

  List<ScriptChunk> _chunks;
  Uint8List _program;

  /**
   * Create a new script.
   * 
   * Either a [Uint8List] or an iterable of [ScriptChunk]s must be passed as argument.
   */
  Script(dynamic script) {
    if (script is Uint8List) {
      _program = new Uint8List.fromList(script);
      return;
    }
    if (script is Iterable<ScriptChunk>) {
      _chunks = new List.from(script, growable: false);
      return;
    }
    throw new ArgumentError(
        "Either a [Uint8List] or an iterable of [ScriptChunk]s must be passed as argument.");
  }

  factory Script.fromString(String string) {
    if (string == null) throw new ArgumentError("parameter should not be null");
    List<ScriptChunk> chunks = new List<ScriptChunk>();
    for (String s in string.split(" ")) {
      if (s == "") continue;
      // try int
      try {
        int val = int.parse(s);
        if (val >= -1 && val <= 16) {
          chunks.add(new ScriptChunk.opCodeChunk(Script.encodeToOpN(val)));
          continue;
        }
//        else
//          Script.writeBytes(out, utils.reverseBytes(utils.encodeMPI(BigInteger.valueOf(val), false)));
      } catch (e) {}
      // try opcode
      if (s.startsWith("OP_")) s = s.substring(3);
      int opcode = ScriptOpCodes.getOpCode(s);
      if (opcode != ScriptOpCodes.OP_INVALIDOPCODE) {
        chunks.add(new ScriptChunk.opCodeChunk(opcode));
        continue;
      }
      // try data
      if (s.startsWith("[") && s.endsWith("]")) {
        chunks.add(new ScriptChunk.dataChunk(CryptoUtils.hexToBytes(s.substring(1, s.length - 1))));
        continue;
      }
      throw new FormatException("The script string is invalid: $string");
    }
    return new Script(chunks);
  }

  Uint8List get program {
    if (_program == null) {
      _program = encode();
    }
    return new Uint8List.fromList(_program);
  }

  List<ScriptChunk> get chunks {
    if (_chunks == null) {
      _parse();
    }
    return new UnmodifiableListView(_chunks);
  }

  @override
  operator ==(Script other) {
    if (other is! Script) return false;
    if (identical(this, other)) return true;
    return utils.equalLists(this.program, other.program);
  }

  @override
  int get hashCode {
    return utils.listHashCode(this.program);
  }

  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.writeAll(chunks, " ");
    return buf.toString();
  }

  void _parse() {
    if (_chunks != null) return;
    List<ScriptChunk> chunks = new List<ScriptChunk>();
    var reader = new bytes.Reader(_program);
    int initialSize = reader.remainingLength;

    while (reader.remainingLength > 0) {
      int startLocationInProgram = initialSize - reader.remainingLength;
      int opcode = reader.readByte();

      int dataToRead = -1;
      if (opcode >= 0 && opcode < ScriptOpCodes.OP_PUSHDATA1) {
        dataToRead = opcode;
      } else if (opcode == ScriptOpCodes.OP_PUSHDATA1) {
        if (reader.remainingLength < 1) {
          throw new ScriptException("Unexpected end of script", this, opcode);
        }
        dataToRead = reader.readByte();
      } else if (opcode == ScriptOpCodes.OP_PUSHDATA2) {
        if (reader.remainingLength < 2) {
          throw new ScriptException("Unexpected end of script", this, opcode);
        }
        dataToRead = reader.readByte() | (reader.readByte() << 8);
      } else if (opcode == ScriptOpCodes.OP_PUSHDATA4) {
        if (reader.remainingLength < 4) {
          throw new ScriptException("Unexpected end of script", this, opcode);
        }
        dataToRead = reader.readByte() |
            (reader.readByte() << 8) |
            (reader.readByte() << 16) |
            (reader.readByte() << 24);
      }

      if (dataToRead == -1) {
        chunks.add(new ScriptChunk.opCodeChunk(opcode, startLocationInProgram));
      } else {
        if (dataToRead > reader.remainingLength) {
          throw new ScriptException(
              "Push of data element that is larger than remaining data", this, opcode);
        }
        chunks.add(new ScriptChunk.dataChunk(reader.readBytes(dataToRead), startLocationInProgram));
      }
    }
    _chunks = chunks;
  }

  Uint8List encode() {
    if (_program != null) return _program;
    var buffer = new bytes.Buffer();
    for (ScriptChunk chunk in chunks) {
      buffer.add(chunk.serialize());
    }
    return buffer.asBytes();
  }

  static Uint8List encodeData(Uint8List data) {
    if (data == null) return new Uint8List(1); // one byte indicating a 0-length sequence
    List<int> result = new List<int>();
    if (data.length < ScriptOpCodes.OP_PUSHDATA1) {
      result.add(data.length);
    } else if (data.length <= 0xff) {
      result.add(ScriptOpCodes.OP_PUSHDATA1);
      result.add(data.length);
    } else if (data.length <= 0xffff) {
      result.add(ScriptOpCodes.OP_PUSHDATA2);
      result.addAll(utils.uintToBytesLE(data.length, 2));
    } else {
      result.add(ScriptOpCodes.OP_PUSHDATA4);
      result.addAll(utils.uintToBytesLE(data.length, 4));
    }
    result.addAll(data);
    return new Uint8List.fromList(result);
  }

  static int decodeFromOpN(int opcode) {
    if (!(opcode == ScriptOpCodes.OP_0 ||
        opcode == ScriptOpCodes.OP_1NEGATE ||
        (opcode >= ScriptOpCodes.OP_1 && opcode <= ScriptOpCodes.OP_16))) {
      throw new ScriptException("Method should be called on an OP_N opcode.", null, opcode);
    }
    if (opcode == ScriptOpCodes.OP_0)
      return 0;
    else if (opcode == ScriptOpCodes.OP_1NEGATE)
      return -1;
    else
      return opcode + 1 - ScriptOpCodes.OP_1;
  }

  static int encodeToOpN(int value) {
    if (!(value >= -1 && value <= 16)) {
      throw new ScriptException("Can only encode for values -1 <= value <= 16.");
    }
    if (value == 0)
      return ScriptOpCodes.OP_0;
    else if (value == -1)
      return ScriptOpCodes.OP_1NEGATE;
    else
      return value - 1 + ScriptOpCodes.OP_1;
  }

  int get sigOpCount {
    int sigOps = 0;
    int lastOpCode = ScriptOpCodes.OP_INVALIDOPCODE;
    for (ScriptChunk chunk in chunks) {
      if (chunk.isOpCode) {
        int opcode = 0xFF & chunk.data[0];
        switch (opcode) {
          case ScriptOpCodes.OP_CHECKSIG:
          case ScriptOpCodes.OP_CHECKSIGVERIFY:
            sigOps++;
            break;
          case ScriptOpCodes.OP_CHECKMULTISIG:
          case ScriptOpCodes.OP_CHECKMULTISIGVERIFY:
            if (lastOpCode >= ScriptOpCodes.OP_1 && lastOpCode <= ScriptOpCodes.OP_16)
              sigOps += decodeFromOpN(lastOpCode);
            else
              sigOps += 20;
            break;
          default:
            break;
        }
        lastOpCode = opcode;
      }
    }
    return sigOps;
  }

  /**
   * Verifies that this script (interpreted as a scriptSig) correctly spends the given scriptPubKey.
   * @param txContainingThis The transaction in which this input scriptSig resides.
   *                         Accessing txContainingThis from another thread while this method runs results in undefined behavior.
   * @param scriptSigIndex The index in txContainingThis of the scriptSig (note: NOT the index of the scriptPubKey).
   * @param scriptPubKey The connected scriptPubKey containing the conditions needed to claim the value.
   * @param enforceP2SH Whether "pay to script hash" rules should be enforced. If in doubt, set to true.
   */
  void correctlySpends(
      Transaction txContainingThis, int scriptSigIndex, Script scriptPubKey, bool enforceP2SH) {
    // Clone the transaction because executing the script involves editing it, and if we die, we'll leave
    // the tx half broken (also it's not so thread safe to work on it directly.
    var oldTx = txContainingThis;
    txContainingThis = new Transaction.empty();
    txContainingThis.bitcoinDeserialize(new bytes.Reader(oldTx.bitcoinSerializedBytes(0)), 0);
    if (this.program.length > 10000 || scriptPubKey.program.length > 10000)
      throw new ScriptException("Script larger than 10,000 bytes");

    DoubleLinkedQueue<Uint8List> stack = new DoubleLinkedQueue<Uint8List>();
    DoubleLinkedQueue<Uint8List> p2shStack = null;

    ScriptExecutor.executeScript(this, stack, txContainingThis, scriptSigIndex);
    if (enforceP2SH) p2shStack = new DoubleLinkedQueue.from(stack);
    ScriptExecutor.executeScript(scriptPubKey, stack, txContainingThis, scriptSigIndex);

    if (stack.length == 0) throw new ScriptException("Stack empty at end of script execution.");

    Uint8List last = stack.removeLast();
    if (!ScriptExecutor.castToBool(last))
      throw new ScriptException("Script resulted in a non-true stack: " + _printStack(stack, last));

    // P2SH is pay to script hash. It means that the scriptPubKey has a special form which is a valid
    // program but it has "useless" form that if evaluated as a normal program always returns true.
    // Instead, miners recognize it as special based on its template - it provides a hash of the real scriptPubKey
    // and that must be provided by the input. The goal of this bizarre arrangement is twofold:
    //
    // (1) You can sum up a large, complex script (like a CHECKMULTISIG script) with an address that's the same
    //     size as a regular address. This means it doesn't overload scannable QR codes/NFC tags or become
    //     un-wieldy to copy/paste.
    // (2) It allows the working set to be smaller: nodes perform best when they can store as many unspent outputs
    //     in RAM as possible, so if the outputs are made smaller and the inputs get bigger, then it's better for
    //     overall scalability and performance.

    // TODO [bitcoinj]: Check if we can take out enforceP2SH if there's a checkpoint at the enforcement block.
    if (enforceP2SH && PayToScriptHashOutputScript.matchesType(scriptPubKey)) {
      for (ScriptChunk chunk in chunks)
        if (chunk.isOpCode && (chunk.data[0] & 0xff) > ScriptOpCodes.OP_16)
          throw new ScriptException(
              "Attempted to spend a P2SH scriptPubKey with a script that contained script ops");

      Uint8List scriptPubKeyBytes = p2shStack.removeLast();
      Script scriptPubKeyP2SH = new Script(scriptPubKeyBytes);

      ScriptExecutor.executeScript(scriptPubKeyP2SH, p2shStack, txContainingThis, scriptSigIndex);

      if (p2shStack.length == 0)
        throw new ScriptException("P2SH stack empty at end of script execution.");

      if (!ScriptExecutor.castToBool(p2shStack.removeLast()))
        throw new ScriptException("P2SH script execution resulted in a non-true stack");
    }
  }

  String _printStack(DoubleLinkedQueue stack, [Uint8List last]) {
    StringBuffer sb = new StringBuffer()..write("[");
    for (Uint8List elem in stack) {
      sb..write("<" + CryptoUtils.bytesToHex(elem) + ">")..write(" ");
    }
    if (last != null) {
      sb.write("<" + CryptoUtils.bytesToHex(last) + ">");
    }
    return (sb..write("]")).toString();
  }
}
