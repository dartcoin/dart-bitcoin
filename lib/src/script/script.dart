part of dartcoin.core;

class Script {
  
  static final int MAX_SCRIPT_ELEMENT_SIZE = 520; //bytes
  static final Script EMPTY_SCRIPT = new _ImmutableScript(new Uint8List(0));
  
  List<ScriptChunk> _chunks;
  Uint8List _bytes;
  
  Script(Uint8List bytes) {
    _bytes = bytes;
    _chunks = null;
  }
  
  Script.fromChunks(List<ScriptChunk> chunks) {
    _chunks = chunks;
    _bytes = null;
  }
  
  Uint8List get bytes {
    if(_bytes == null) {
      _bytes = encode();
    }
    return _bytes;
  }
  
  void set bytes(Uint8List bytes) {
    _bytes = bytes;
    _chunks = null;
  }
  
  List<ScriptChunk> get chunks {
    if(_chunks == null) {
      parse();
    }
    return _chunks;
  }
  
  @override
  operator ==(Script other) {
    if(!(other is Script)) return false;
    return Utils.equalLists(bytes, other.bytes);
  }
  
  //TODO hashcode?
  
  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.writeAll(chunks, " ");
    return buf.toString();
  }

  /**
   * <p>Whether or not this is a scriptPubKey representing a pay-to-script-hash output. In such outputs, the logic that
   * controls reclamation is not actually in the output at all. Instead there's just a hash, and it's up to the
   * spending input to provide a program matching that hash. This rule is "soft enforced" by the network as it does
   * not exist in Satoshis original implementation. It means blocks containing P2SH transactions that don't match
   * correctly are considered valid, but won't be mined upon, so they'll be rapidly re-orgd out of the chain. This
   * logic is defined by <a href="https://en.bitcoin.it/wiki/BIP_0016">BIP 16</a>.</p>
   *
   * <p>bitcoinj does not support creation of P2SH transactions today. The goal of P2SH is to allow short addresses
   * even for complex scripts (eg, multi-sig outputs) so they are convenient to work with in things like QRcodes or
   * with copy/paste, and also to minimize the size of the unspent output set (which improves performance of the
   * Bitcoin system).</p>
   */
  bool get isPayToScriptHash {
    // We have to check against the serialized form because BIP16 defines a P2SH output using an exact byte
    // template, not the logical program structure. Thus you can have two programs that look identical when
    // printed out but one is a P2SH script and the other isn't! :(
    return bytes.length == 23 &&
        (bytes[0]  & 0xff) == ScriptOpCodes.OP_HASH160 &&
        (bytes[1]  & 0xff) == 0x14 &&
        (bytes[22] & 0xff) == ScriptOpCodes.OP_EQUAL;
  }
  
  void parse() {
    List<ScriptChunk> chunks = new List();
    DoubleLinkedQueue<int> bytes = new DoubleLinkedQueue.from(_bytes); // because there is removeLast but not removeFirst
    int initialSize = bytes.length;
    
    while(bytes.length > 0) {
      int startLocationInProgram = initialSize - bytes.length;
      int opcode = bytes.removeFirst();
      
      int dataToRead = -1;
      if(opcode >= 0 && opcode < ScriptOpCodes.OP_PUSHDATA1) {
        dataToRead = opcode;
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA1) {
        if(bytes.length < 1) throw new ScriptException("Unexpected end of script", this, opcode);
        dataToRead = bytes.removeFirst();
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA2) {
        if(bytes.length < 2) throw new ScriptException("Unexpected end of script", this, opcode);
        dataToRead = bytes.removeFirst() | (bytes.removeFirst() << 8);
      }
      else if(opcode == ScriptOpCodes.OP_PUSHDATA4) {
        if(bytes.length < 2) throw new ScriptException("Unexpected end of script", this, opcode);
        dataToRead = bytes.removeFirst() | (bytes.removeFirst() << 8) | (bytes.removeFirst() << 16) | (bytes.removeFirst() << 24);
      }
      
      if(dataToRead < 0) {
        chunks.add(new ScriptChunk(true, new Uint8List.fromList([opcode]), startLocationInProgram));
      }
      else {
        if (dataToRead > bytes.length)
          throw new ScriptException("Push of data element that is larger than remaining data", this, opcode);
        chunks.add(new ScriptChunk(false, new Uint8List.fromList(_takeFirstN(dataToRead, bytes)), startLocationInProgram));
      }
    }
    _chunks = chunks;
  }
  
  List<int> _takeFirstN(int n, DoubleLinkedQueue<int> reverseBuffer) {
    List<int> result = new List<int>();
    for(int i ; i < n ; i++) {
      result.add(reverseBuffer.removeFirst());
    }
    return result;
  }
  
  Uint8List encode() {
    if(_bytes != null) return _bytes;
    List<int> bytes = new List();
    for(ScriptChunk chunk in chunks) {
      bytes.addAll(chunk.data);
    }
    return new Uint8List.fromList(bytes);
  }
  
  static Uint8List encodeData(Uint8List data) {
    List<int> result = new List<int>();
    if(data.length < ScriptOpCodes.OP_PUSHDATA1) {
      result.add(data.length);
    }
    else if(data.length <= 0xff) {
      result.add(ScriptOpCodes.OP_PUSHDATA1);
      result.add(data.length);
    } else if (data.length <= 0xffff) {
      result.add(ScriptOpCodes.OP_PUSHDATA2);
      result.addAll(Utils.uintToBytesLE(data.length, 2));
    } else {
      result.add(ScriptOpCodes.OP_PUSHDATA4);
      result.addAll(Utils.uintToBytesLE(data.length, 4));
    }
    result.addAll(data);
    return new Uint8List.fromList(result);
  }
  
  static int decodeFromOpN(int opcode) {
    if(! (opcode == ScriptOpCodes.OP_0 || opcode == ScriptOpCodes.OP_1NEGATE || 
        (opcode >= ScriptOpCodes.OP_1 && opcode <= ScriptOpCodes.OP_16)) ) {
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
    if(! (value >= -1 && value <= 16) ) {
      throw new ScriptException("Can only encode for values -1 <= value <= 16.");
    }
    if (value == 0)
      return ScriptOpCodes.OP_0;
    else if (value == -1)
      return ScriptOpCodes.OP_1NEGATE;
    else
      return value - 1 + ScriptOpCodes.OP_1;
  }
  
}

class _ImmutableScript extends Script {
  
  _ImmutableScript(Uint8List bytes) : super(bytes);
  
  @override
  void set bytes(Uint8List bytes) {
    throw new ScriptException("Operation not allowed on immutable script.", this);
  }
  
}






