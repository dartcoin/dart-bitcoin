part of dartcoin.core;

class Transaction extends Object with BitcoinSerialization {
  
  static const int TRANSACTION_VERSION = 1;

  Hash256 _hash;
  
  int _version;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  int _lockTime;
  
  Transaction({ Hash256 txid,
                List<TransactionInput> inputs, 
                List<TransactionOutput> outputs,
                int lockTime: 0,
                BitcoinSerialization parent,
                int version: TRANSACTION_VERSION,
                NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _hash = txid;
    _inputs = inputs != null ? inputs : new List<TransactionInput>();
    _outputs = outputs != null ? outputs : new List<TransactionOutput>();
    _lockTime = lockTime;
    _parent = parent;
    _version = version;
    this.params = params;
  }
  
  // required for serialization
  Transaction._newInstance();
  
  factory Transaction.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) => 
        new BitcoinSerialization.deserialize(new Transaction._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, parent: parent);
  
  int get version {
    _needInstance();
    return _version;
  }
  
  List<TransactionInput> get inputs {
    _needInstance();
    return new UnmodifiableListView(_inputs);
  }
  
  void set inputs(List<TransactionInput> inputs) {
    _needInstance(true);
    for(TransactionInput input in inputs)
      input._parent = this;
    _inputs = inputs;
  }
  
  List<TransactionOutput> get outputs {
    _needInstance();
    return new UnmodifiableListView(_outputs);
  }
  
  void set outputs(List<TransactionOutput> outputs) {
    _needInstance(true);
    for(TransactionOutput output in outputs)
      output._parent = this;
    _outputs = outputs;
  }
  
  int get lockTime {
    _needInstance();
    return _lockTime;
  }
  
  void set lockTime(int lockTime) {
    _needInstance(true);
    _lockTime = lockTime;
  }

  Hash256 get hash {
    if(_hash == null) {
      _hash = _calculateHash();
    }
    return _hash;
  }

  Hash256 _calculateHash() {
    return new Hash256(utils.reverseBytes(crypto.doubleDigest(serialize())));
  }

  Hash256 get txid => hash;
  
  int get amount {
    _needInstance();
    int totalAmount = 0;
    try {
      for(TransactionInput input in inputs) {
        Transaction from = input.outpoint.transaction;
        TransactionOutput output = from.outputs[input.outpoint.index];
        totalAmount += output.value;
      }
      return totalAmount;
    } on NoSuchMethodError {
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

  /**
   * Gets the count of regular SigOps in this transactions
   */
  int get sigOpCount {
    _needInstance();
    int sigOps = 0;
    for (TransactionInput input in _inputs)
      sigOps += input.scriptSig.sigOpCount;
    for (TransactionOutput output in _outputs)
      sigOps += output.scriptPubKey.sigOpCount;
    return sigOps;
  }
  
  Block get parentBlock => _parent;
  
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
    if(input is! TransactionInput && input is! TransactionOutput) 
      throw new ArgumentError("The input must be either a TransactionInput or TransactionOutput object.");
    if(input is TransactionOutput)
      input = new TransactionInput.fromOutput(input, parentTransaction: this, params: params);
    _needInstance(true);
    input._parent = this;
    _inputs.add(input);
    return input;
  }

  /**
   * Adds a new and fully signed input for the given parameters. Note that this method is <b>not</b> thread safe
   * and requires external synchronization. Please refer to general documentation on Bitcoin scripting and contracts
   * to understand the values of sigHash and anyoneCanPay: otherwise you can use the other form of this method
   * that sets them to typical defaults.
   *
   * @throws [ScriptException] if the [scriptPubKey] is not a pay to address or pay to pubkey script.
   */
  TransactionInput addSignedInput(TransactionOutPoint prevOut, Script scriptPubKey, KeyPair sigKey,
                                       [SigHash sigHash = SigHash.ALL, bool anyoneCanPay = false]) {
    TransactionInput input = new TransactionInput(
        outpoint: prevOut,  
        params: params);
    addInput(input); // this method calls _needInstance(true) for us
    int sigHashFlags = SigHash.sigHashFlagsValue(sigHash, anyoneCanPay);
    Hash256 hash = hashForSignature(_inputs.length - 1, scriptPubKey, sigHashFlags);
    ECDSASignature ecSig = sigKey.sign(hash);
    TransactionSignature txSig = new TransactionSignature(ecSig, mode: sigHash, anyoneCanPay: anyoneCanPay);
    if (PayToPubKeyOutputScript.matchesType(scriptPubKey))
      input.scriptSig = new PayToPubKeyInputScript(txSig);
    else if (PayToPubKeyHashOutputScript.matchesType(scriptPubKey))
      input.scriptSig = new PayToPubKeyHashInputScript(txSig, sigKey);
    else
      throw new ScriptException("Don't know how to sign for this kind of scriptPubKey: $scriptPubKey");
    return input;
  }
  
  void clearInputs() {
    _needInstance(true);
    _inputs.forEach((i) => i._parent = null);
    _inputs.clear();
  }
  
  /**
   * Adds the transaction output to this transaction and returns it.
   */
  TransactionOutput addOutput(TransactionOutput output) {
    _needInstance(true);
    output._parent = this;
    _outputs.add(output);
    return output;
  }
  
  void clearOutputs() {
    _needInstance(true);
    _outputs.forEach((o) => o._parent = null);
    _outputs.clear();
  }

  /**
   * Checks the transaction contents for sanity, in ways that can be done in a standalone manner.
   * Does <b>not</b> perform all checks on a transaction such as whether the inputs are already spent.
   *
   * @throws VerificationException
   */
  void verify() {
    _needInstance();
    if(_inputs.length == 0 || _outputs.length == 0)
      throw new VerificationException("Transaction had no inputs or no outputs.");
    if(this.serializationLength > Block.MAX_BLOCK_SIZE)
      throw new VerificationException("Transaction larger than MAX_BLOCK_SIZE");

    int valueOut = 0;
    for(TransactionOutput output in _outputs) {
      if(output.value < 0)
        throw new VerificationException("Transaction output negative");
      valueOut += output.value;
    }
    if(valueOut > NetworkParameters.MAX_MONEY)
      throw new VerificationException("Total transaction output value greater than possible");

    if(isCoinbase) {
      if(_inputs[0].scriptSig.bytes.length < 2 || _inputs[0].scriptSig.bytes.length > 100)
        throw new VerificationException("Coinbase script size out of range");
    } else {
      for(TransactionInput input in _inputs)
        if(input.isCoinbase)
          throw new VerificationException("Coinbase input as input in non-coinbase transaction");
    }
  }
  
  @override
  operator ==(Transaction other) {
    if(other is! Transaction) return false;
    if(identical(this, other)) return true;
    return hash == other.hash;
  }
  
  @override
  int get hashCode => hash.hashCode;
  
  /**
   * 
   * 
   * The [connectedScript] parameter must be either of typr [Script] or [Uint8List].
   */
  Hash256 hashForSignature(int inputIndex, dynamic connectedScript, int sigHashFlags) {
    _needInstance(true);
    // The SIGHASH flags are used in the design of contracts, please see this page for a further understanding of
    // the purposes of the code in this method:
    //
    //   https://en.bitcoin.it/wiki/Contracts
    
    // Store all the input scripts and clear them in preparation for signing. If we're signing a fresh
    // transaction that step isn't very helpful, but it doesn't add much cost relative to the actual
    // EC math so we'll do it anyway.
    //
    // Also store the input sequence numbers in case we are clearing them with SigHash.NONE/SINGLE
    if(connectedScript is Script)
      connectedScript = connectedScript.bytes;
    if(connectedScript is! Uint8List)
      throw new ArgumentError("The connectedScript parameter must be either of type Script or Uint8List.");
    
    List<Script> inputScripts = new List<Script>(_inputs.length);
    List<int> inputSequenceNumbers = new List<int>(_inputs.length);
    for (int i = 0; i < _inputs.length; i++) {
      inputScripts[i] = _inputs[i].scriptSig;
      inputSequenceNumbers[i] = _inputs[i].sequence;
      _inputs[i].scriptSig = Script.EMPTY_SCRIPT;
    }

    // This step has no purpose beyond being synchronized with the reference clients bugs. OP_CODESEPARATOR
    // is a legacy holdover from a previous, broken design of executing scripts that shipped in Bitcoin 0.1.
    // It was seriously flawed and would have let anyone take anyone elses money. Later versions switched to
    // the design we use today where scripts are executed independently but share a stack. This left the
    // OP_CODESEPARATOR instruction having no purpose as it was only meant to be used internally, not actually
    // ever put into scripts. Deleting OP_CODESEPARATOR is a step that should never be required but if we don't
    // do it, we could split off the main chain.
    connectedScript = ScriptExecutor.removeAllInstancesOfOp(connectedScript, ScriptOpCodes.OP_CODESEPARATOR);

    // Set the input to the script of its output. Satoshi does this but the step has no obvious purpose as
    // the signature covers the hash of the prevout transaction which obviously includes the output script
    // already. Perhaps it felt safer to him in some way, or is another leftover from how the code was written.
    TransactionInput input = _inputs[inputIndex];

    input.scriptSig = new Script(connectedScript);

    List<TransactionOutput> outputs = _outputs;
    if ((sigHashFlags & 0x1f) == (SigHash.NONE.value)) {
      // SIGHASH_NONE means no outputs are signed at all - the signature is effectively for a "blank cheque".
      _outputs = new List<TransactionOutput>(0);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < _inputs.length; i++)
        if (i != inputIndex)
          _inputs[i]._sequence = 0;
    } else if ((sigHashFlags & 0x1f) == (SigHash.SINGLE.value)) {
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
          _inputs[i].scriptSig = inputScripts[i];
          _inputs[i].sequence = inputSequenceNumbers[i];
        }
        _outputs = outputs;
        // Satoshis bug is that SignatureHash was supposed to return a hash and on this codepath it
        // actually returns the constant "1" to indicate an error, which is never checked for. Oops.
        return new Hash256("0100000000000000000000000000000000000000000000000000000000000000");
      }
      // In SIGHASH_SINGLE the outputs after the matching input index are deleted, and the outputs before
      // that position are "nulled out". Unintuitively, the value in a "null" transaction is set to -1.
      _outputs = new List.from(_outputs.sublist(0, inputIndex + 1));
      for (int i = 0; i < inputIndex; i++)
        _outputs[i] = new TransactionOutput(value: -1, scriptPubKey: Script.EMPTY_SCRIPT, parent: this, params: params);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < _inputs.length; i++)
        if (i != inputIndex)
          _inputs[i].sequence = 0;
    }

    List<TransactionInput> inputs = _inputs;
    if ((sigHashFlags & SigHash.ANYONE_CAN_PAY) == SigHash.ANYONE_CAN_PAY) {
      // SIGHASH_ANYONECANPAY means the signature in the input is not broken by changes/additions/removals
      // of other inputs. For example, this is useful for building assurance contracts.
      _inputs = [input];
    }
    
    Uint8List toHash = new Uint8List.fromList(new List<int>()
      ..addAll(serialize())
    // We also have to write a hash type (sigHashType is actually an unsigned char)
      ..add(0x000000ff & sigHashFlags));
    // Note that this is NOT reversed to ensure it will be signed correctly. If it were to be printed out
    // however then we would expect that it is IS reversed.
    Hash256 hash = new Hash256(crypto.doubleDigest(toHash));

    // Put the transaction back to how we found it.
    _needInstance(true); // uncache
    _inputs = inputs;
    for (int i = 0; i < inputs.length; i++) {
      inputs[i].scriptSig = inputScripts[i];
      inputs[i].sequence = inputSequenceNumbers[i];
    }
    _outputs = outputs;
    return hash;
  }

  @override
  void _serialize(ByteSink sink) {
    _writeUintLE(sink, _version);
    _writeVarInt(sink, _inputs.length);
    for(TransactionInput input in _inputs)
      _writeObject(sink, input);
    _writeVarInt(sink, _outputs.length);
    for(TransactionOutput output in _outputs)
      _writeObject(sink, output);
    _writeUintLE(sink, _lockTime);
  }

  @override
  void _deserialize() {
    _version = _readUintLE();
    int nbInputs = _readVarInt();
    _inputs = new List<TransactionInput>();
    for(int i = 0 ; i < nbInputs ; i++) {
      _inputs.add(_readObject(new TransactionInput._newInstance()));
    }
    int nbOutputs = _readVarInt();
    _outputs = new List<TransactionOutput>();
    for(int i = 0 ; i < nbOutputs ; i++) {
      _outputs.add(_readObject(new TransactionOutput._newInstance()));
    }
    _lockTime = _readUintLE();
  }
  
  @override
  void _deserializeLazy() {
    _serializationCursor += 4;
    // inputs
    int nbInputs = _readVarInt();
    for(int i = 0 ; i < nbInputs ; i++)
      _readObject(new TransactionInput._newInstance(), lazy: true);
    // outputs
    int nbOutputs = _readVarInt();
    for(int i = 0 ; i < nbOutputs ; i++)
      _readObject(new TransactionOutput._newInstance(), lazy: true);
    // locktime
    _serializationCursor += 4;
  }
  
  @override
  void _needInstance([bool clearCache = false]) {
    super._needInstance(clearCache);
    if(clearCache)
      _hash = null;
  }
}








