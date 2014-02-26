part of dartcoin.core;

class Transaction extends Object with BitcoinSerialization {
  
  static const int TRANSACTION_VERSION = 1;
  
  Sha256Hash _hash;
  
  int _version;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  int _lockTime;
  
  Block _parent;
  
  Transaction({ Sha256Hash txid,
                List<TransactionInput> inputs, 
                List<TransactionOutput> outputs,
                int lockTime,
                Block parentBlock,
                int version: TRANSACTION_VERSION,
                NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _hash = txid;
    _inputs = inputs;
    _outputs = outputs;
    _lockTime = lockTime;
    _parent = parentBlock;
    _version = version;
    this.params = params;
  }
  
  factory Transaction.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) => 
        new BitcoinSerialization.deserialize(new Transaction(), bytes, length: length, lazy: lazy, params: params);
  
  int get version {
    _needInstance();
    _version;
  }
  
  List<TransactionInput> get inputs {
    _needInstance();
    return new UnmodifiableListView(_inputs);
  }
  
  List<TransactionOutput> get outputs {
    _needInstance();
    return new UnmodifiableListView(_outputs);
  }
  
  int get lockTime {
    _needInstance();
    return _lockTime;
  }
  
  Sha256Hash get hash {
    if(_hash == null) {
      _calculateHash();
    }
    return _hash;
  }
  
  Sha256Hash get txid {
    return hash;
  }
  
  int get amount {
    _needInstance();
    int totalAmount = 0;
    try {
      for(TransactionInput input in inputs) {
        Transaction from = input.outpoint.transaction;
        TransactionOutput output = from.outputs[input.outpoint.index];
        totalAmount += output.value;
      }
    }
    on NoSuchMethodError catch(e) {
      throw new Exception("Not all inputs fully known. Unable to calculate total amount.");
    }
  }
  
  int get fee {
    _needInstance();
    int totalIn = amount;
    int totalOut = 0;
    try {
      for(TransactionOutput output in outputs) {
        totalOut += output.value;
      }
    }
    on NoSuchMethodError catch(e) {
      throw new Exception("Not all outputs fully known. Unable to calculate fee.");
    }
    return totalIn - totalOut;
  }
  
  bool get isCoinbase {
    _needInstance();
    return inputs.length == 1 && inputs[0].isCoinbase;
  }
  
  Block get parentBlock {
    return _parent;
  }
  
  void set parentBlock(Block parentBlock) {
    _parent = parentBlock;
  }
  
  /**
   * Adds a TransactionInput to this transaction and returns it.
   * 
   * An input can be a TransactionInput object, but it can also be created
   * from a TransactionOutput object.
   */
  TransactionInput addInput(dynamic input) {
    if(!(input is TransactionInput || input is TransactionOutput)) 
      throw new Exception("The input must be either a TransactionInput or TransactionOutput object.");
    if(input is TransactionOutput)
      input = new TransactionInput(params: params, parentTransaction: this, output: input);
    _needInstance(true);
    input.parentTransaction = this;
    _inputs.add(input);
    return input;
  }
  
  //TODO add signedinput
  
  void clearInputs() {
    _needInstance(true);
    _inputs.forEach((i) => i.parentTransaction = null);
    _inputs.clear();
  }
  
  /**
   * Adds the transaction output to this transaction and returns it.
   */
  TransactionOutput addOutput(TransactionOutput output) {
    _needInstance(true);
    output.parentTransaction = this;
    _outputs.add(output);
    return output;
  }
  
  void clearOutputs() {
    _needInstance(true);
    _outputs.forEach((o) => o.parentTransaction = null);
    _outputs.clear();
  }
  
  @override
  operator ==(Transaction other) {
    return other is Transaction &&
        version == other.version && 
        Utils.equalLists(inputs, other.inputs) && 
        Utils.equalLists(outputs, other.outputs) &&
        lockTime == other.lockTime;
  }
  
  @override
  int get hashCode {
    _needInstance();
    // first 32 bits of txid hash
    return _hash.bytes[0] << 24 + _hash.bytes[1] << 16 + _hash.bytes[2] << 8 + _hash.bytes[3];
  }
  
  void _calculateHash() {
    _needInstance(true);
    _hash = Sha256Hash.doubleDigest(serialize());
  }
  
  Sha256Hash hashForSignature(int inputIndex, Uint8List connectedScript, int sigHashType) {
    _needInstance();
    // The SIGHASH flags are used in the design of contracts, please see this page for a further understanding of
    // the purposes of the code in this method:
    //
    //   https://en.bitcoin.it/wiki/Contracts
    
    // Store all the input scripts and clear them in preparation for signing. If we're signing a fresh
    // transaction that step isn't very helpful, but it doesn't add much cost relative to the actual
    // EC math so we'll do it anyway.
    //
    // Also store the input sequence numbers in case we are clearing them with SigHash.NONE/SINGLE
    List<Script> inputScripts = new List<Script>(_inputs.length);
    List<int> inputSequenceNumbers = new List<int>(_inputs.length);
    for (int i = 0; i < _inputs.length; i++) {
      inputScripts[i] = _inputs[i].scriptSig;
      inputSequenceNumbers[i] = _inputs[i].sequence;
      _inputs[i]._scriptSig = Script.EMPTY_SCRIPT;
    }

    // This step has no purpose beyond being synchronized with the reference clients bugs. OP_CODESEPARATOR
    // is a legacy holdover from a previous, broken design of executing scripts that shipped in Bitcoin 0.1.
    // It was seriously flawed and would have let anyone take anyone elses money. Later versions switched to
    // the design we use today where scripts are executed independently but share a stack. This left the
    // OP_CODESEPARATOR instruction having no purpose as it was only meant to be used internally, not actually
    // ever put into scripts. Deleting OP_CODESEPARATOR is a step that should never be required but if we don't
    // do it, we could split off the main chain.
    connectedScript = _ScriptExecutor.removeAllInstancesOfOp(connectedScript, ScriptOpCodes.OP_CODESEPARATOR);

    // Set the input to the script of its output. Satoshi does this but the step has no obvious purpose as
    // the signature covers the hash of the prevout transaction which obviously includes the output script
    // already. Perhaps it felt safer to him in some way, or is another leftover from how the code was written.
    TransactionInput input = _inputs[inputIndex];
    input._scriptSig = new Script(connectedScript);

    List<TransactionOutput> outputs = _outputs;
    if ((sigHashType & 0x1f) == (SigHash.NONE.value + 1)) {
      // SIGHASH_NONE means no outputs are signed at all - the signature is effectively for a "blank cheque".
      _outputs = new List<TransactionOutput>(0);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < _inputs.length; i++)
        if (i != inputIndex)
          _inputs[i]._sequence = 0;
    } else if ((sigHashType & 0x1f) == (SigHash.SINGLE.value + 1)) {
      // SIGHASH_SINGLE means only sign the output at the same index as the input (ie, my output).
      if (inputIndex >= _outputs.length) {
        // The input index is beyond the number of outputs, it's a buggy signature made by a broken
        // Bitcoin implementation. The reference client also contains a bug in handling this case:
        // any transaction output that is signed in this case will result in both the signed output
        // and any future outputs to this public key being steal-able by anyone who has
        // the resulting signature and the public key (both of which are part of the signed tx input).
        // Put the transaction back to how we found it.
        //
        // TODO: (from bitcoinj) Only allow this to happen if we are checking a signature, not signing a transactions
        for (int i = 0 ; i < _inputs.length ; i++) {
          _inputs[i]._scriptSig = inputScripts[i];
          _inputs[i]._sequence = inputSequenceNumbers[i];
        }
        _outputs = outputs;
        // Satoshis bug is that SignatureHash was supposed to return a hash and on this codepath it
        // actually returns the constant "1" to indicate an error, which is never checked for. Oops.
        return new Sha256Hash("0100000000000000000000000000000000000000000000000000000000000000");
      }
      // In SIGHASH_SINGLE the outputs after the matching input index are deleted, and the outputs before
      // that position are "nulled out". Unintuitively, the value in a "null" transaction is set to -1.
      _outputs = new List.from(_outputs.sublist(0, inputIndex + 1));
      for (int i = 0; i < inputIndex; i++)
        _outputs[i] = new TransactionOutput(value: BigInteger.ONE.negate_op(), scriptPubKey: Script.EMPTY_SCRIPT, parent: this, params: params);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < _inputs.length; i++)
        if (i != inputIndex)
          _inputs[i]._sequence = 0;
    }

    List<TransactionInput> inputs = this.inputs;
    if ((sigHashType & SigHash.ANYONE_CAN_PAY) == SigHash.ANYONE_CAN_PAY) {
      // SIGHASH_ANYONECANPAY means the signature in the input is not broken by changes/additions/removals
      // of other inputs. For example, this is useful for building assurance contracts.
      _inputs = new List<TransactionInput>();
      _inputs.add(input);
    }
    
    List<int> toHash = new List<int>()
      ..addAll(this.serialize())
    // We also have to write a hash type (sigHashType is actually an unsigned char)
      ..add(0x000000ff & sigHashType);
    // Note that this is NOT reversed to ensure it will be signed correctly. If it were to be printed out
    // however then we would expect that it is IS reversed.
    Sha256Hash hash = new Sha256Hash(Utils.doubleDigest(toHash));

    // Put the transaction back to how we found it.
    _inputs = inputs;
    for (int i = 0; i < inputs.length; i++) {
      inputs[i]._scriptSig = inputScripts[i];
      inputs[i]._sequence = inputSequenceNumbers[i];
    }
    _outputs = outputs;
    return hash;
    
  }
  
  Uint8List _serialize() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesBE(version, 4))
      ..addAll(new VarInt(inputs.length).serialize())
      ..addAll(inputs.map((input) => input.serialize()))
      ..addAll(new VarInt(outputs.length).serialize())
      ..addAll(outputs.map((output) => output.serialize()))
      ..addAll(Utils.uintToBytesBE(lockTime, 4)));
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    _version = Utils.bytesToUintBE(bytes, 4);
    offset += 4;
    _inputs = new List<TransactionInput>();
    VarInt nbInputs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbInputs.serializationLength;
    for(int i = 0 ; i < nbInputs.value ; i++) {
      TransactionInput input = new TransactionInput.deserialize(bytes.sublist(offset));
      offset += input.serializationLength;
      _inputs.add(input);
    }
    _outputs = new List<TransactionOutput>();
    VarInt nbOutputs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbOutputs.serializationLength;
    for(int i = 0 ; i < nbOutputs.value ; i++) {
      TransactionOutput output = new TransactionOutput.deserialize(bytes.sublist(offset));
      offset += output.serializationLength;
      _outputs.add(output);
    }
    _lockTime = Utils.bytesToUintBE(bytes.sublist(offset), 4);
    offset += 4;
    return offset;
  }
  
  @override
  void _needInstance([bool clearCache]) {
    super._needInstance(clearCache);
    _hash = null;
  }
}








