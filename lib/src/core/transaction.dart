part of dartcoin.core;

class Transaction extends BitcoinSerializable {
  
  static const int TRANSACTION_VERSION = 1;

  Hash256 _hash;
  
  int version;
  List<TransactionInput> inputs;
  List<TransactionOutput> outputs;
  int lockTime;
  
  Transaction({ Hash256 hash,
                List<TransactionInput> this.inputs,
                List<TransactionOutput> this.outputs,
                int this.lockTime: 0,
                int this.version: TRANSACTION_VERSION}) {
    _hash = hash;
    inputs = inputs ?? new List<TransactionInput>();
    outputs = outputs ?? new List<TransactionOutput>();
  }

  factory Transaction.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new Transaction.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }
  
  /// Create an empty instance.
  Transaction.empty();

  Hash256 get hash {
    if (_hash == null) {
      _hash = calculateHash();
    }
    return _hash;
  }

  Hash256 calculateHash() {
    var buffer = new bytes.Buffer();
    bitcoinSerialize(buffer, 0);//TODO pver here?
    Uint8List checksum = crypto.doubleDigest(buffer.asBytes());
    return new Hash256(utils.reverseBytes(checksum));
  }

  Hash256 get txid => hash;
  
  int get amount {
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
    int totalIn = amount;
    int totalOut = 0;
    try {
      for(TransactionOutput output in outputs) {
        totalOut += output.value;
      }
    }
    on NoSuchMethodError {
      throw new Exception("Not all outputs fully known. Unable to calculate fee.");
    }
    return totalIn - totalOut;
  }
  
  bool get isCoinbase {
    return inputs.length == 1 && inputs[0].isCoinbase;
  }

  /**
   * Gets the count of regular SigOps in this transactions
   */
  int get sigOpCount {
    int sigOps = 0;
    for (TransactionInput input in inputs)
      sigOps += input.scriptSig.sigOpCount;
    for (TransactionOutput output in outputs)
      sigOps += output.scriptPubKey.sigOpCount;
    return sigOps;
  }

  
  /**
   * Adds a TransactionInput to this transaction and returns it.
   */
  TransactionInput addInput(TransactionInput input) {
    inputs.add(input);
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
  void addSignedInput(TransactionOutPoint prevOut, Script scriptPubKey, KeyPair sigKey,
                                       [SigHash sigHash = SigHash.ALL, bool anyoneCanPay = false]) {
    TransactionInput input = new TransactionInput(outpoint: prevOut);
    addInput(input);
    int sigHashFlags = SigHash.sigHashFlagsValue(sigHash, anyoneCanPay);
    Hash256 hash = hashForSignature(inputs.length - 1, scriptPubKey, sigHashFlags);
    ECDSASignature ecSig = sigKey.sign(hash);
    TransactionSignature txSig = new TransactionSignature(ecSig, mode: sigHash, anyoneCanPay: anyoneCanPay);
    if (PayToPubKeyOutputScript.matchesType(scriptPubKey))
      input.scriptSig = new PayToPubKeyInputScript(txSig);
    else if (PayToPubKeyHashOutputScript.matchesType(scriptPubKey))
      input.scriptSig = new PayToPubKeyHashInputScript(txSig, sigKey);
    else
      throw new ScriptException("Don't know how to sign for this kind of scriptPubKey: $scriptPubKey");
  }
  
  void clearInputs() {
    inputs = new List<TransactionInput>();
  }
  
  /**
   * Adds the transaction output to this transaction.
   */
  void addOutput(TransactionOutput output) {
    outputs.add(output);
  }
  
  void clearOutputs() {
    outputs = new List<TransactionOutput>();
  }

  /**
   * Checks the transaction contents for sanity, in ways that can be done in a standalone manner.
   * Does <b>not</b> perform all checks on a transaction such as whether the inputs are already spent.
   *
   * @throws VerificationException
   */
  //TODO do this somewhere else
  void verify() {
    if(inputs.length == 0 || outputs.length == 0)
      throw new VerificationException("Transaction had no inputs or no outputs.");
    if(bitcoinSerializedBytes(0).length > Block.MAX_BLOCK_SIZE)
      throw new VerificationException("Transaction larger than MAX_BLOCK_SIZE");

    int valueOut = 0;
    for(TransactionOutput output in outputs) {
      if(output.value < 0)
        throw new VerificationException("Transaction output negative");
      valueOut += output.value;
    }
    if(valueOut > NetworkParameters.MAX_MONEY)
      throw new VerificationException("Total transaction output value greater than possible");

    if(isCoinbase) {
      if(inputs[0].scriptSig.program.length < 2 || inputs[0].scriptSig.program.length > 100)
        throw new VerificationException("Coinbase script size out of range");
    } else {
      for(TransactionInput input in inputs)
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
  int get hashCode => (hash ?? calculateHash()).hashCode;
  
  /**
   * 
   * 
   * The [connectedScript] parameter must be either of typr [Script] or [Uint8List].
   */
  Hash256 hashForSignature(int inputIndex, dynamic connectedScript, int sigHashFlags) {
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
      connectedScript = connectedScript.program;
    if(connectedScript is! Uint8List)
      throw new ArgumentError("The connectedScript parameter must be either of type Script or Uint8List.");
    
    List<Script> inputScripts = new List<Script>(inputs.length);
    List<int> inputSequenceNumbers = new List<int>(inputs.length);
    for (int i = 0; i < inputs.length; i++) {
      inputScripts[i] = inputs[i].scriptSig;
      inputSequenceNumbers[i] = inputs[i].sequence;
      inputs[i].scriptSig = Script.EMPTY_SCRIPT;
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
    TransactionInput input = inputs[inputIndex];

    input.scriptSig = new Script(connectedScript);

    List<TransactionOutput> originalOutputs = outputs;
    if ((sigHashFlags & 0x1f) == (SigHash.NONE.value)) {
      // SIGHASH_NONE means no outputs are signed at all - the signature is effectively for a "blank cheque".
      outputs = new List<TransactionOutput>(0);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < inputs.length; i++)
        if (i != inputIndex)
          inputs[i].sequence = 0;
    } else if ((sigHashFlags & 0x1f) == (SigHash.SINGLE.value)) {
      // SIGHASH_SINGLE means only sign the output at the same index as the input (ie, my output).
      if (inputIndex >= outputs.length) {
        // The input index is beyond the number of outputs, it's a buggy signature made by a broken
        // Bitcoin implementation. The reference client also contains a bug in handling this case:
        // any transaction output that is signed in this case will result in both the signed output
        // and any future outputs to this public key being steal-able by anyone who has
        // the resulting signature and the public key (both of which are part of the signed tx input).
        // Put the transaction back to how we found it.
        //
        // TODO: (from bitcoinj) Only allow this to happen if we are checking a signature, not signing a transactions
        for (int i = 0 ; i < inputs.length ; i++) {
          inputs[i].scriptSig = inputScripts[i];
          inputs[i].sequence = inputSequenceNumbers[i];
        }
        outputs = originalOutputs;
        // Satoshis bug is that SignatureHash was supposed to return a hash and on this codepath it
        // actually returns the constant "1" to indicate an error, which is never checked for. Oops.
        return new Hash256("0100000000000000000000000000000000000000000000000000000000000000");
      }
      // In SIGHASH_SINGLE the outputs after the matching input index are deleted, and the outputs before
      // that position are "nulled out". Unintuitively, the value in a "null" transaction is set to -1.
      outputs = new List.from(outputs.sublist(0, inputIndex + 1));
      for (int i = 0; i < inputIndex; i++)
        outputs[i] = new TransactionOutput(value: -1, scriptPubKey: Script.EMPTY_SCRIPT);
      // The signature isn't broken by new versions of the transaction issued by other parties.
      for (int i = 0; i < inputs.length; i++)
        if (i != inputIndex)
          inputs[i].sequence = 0;
    }

    List<TransactionInput> originalInputs = this.inputs;
    if ((sigHashFlags & SigHash.ANYONE_CAN_PAY) == SigHash.ANYONE_CAN_PAY) {
      // SIGHASH_ANYONECANPAY means the signature in the input is not broken by changes/additions/removals
      // of other inputs. For example, this is useful for building assurance contracts.
      inputs = [input];
    }

    var buffer = new bytes.Buffer();
    bitcoinSerialize(buffer, 0);
    Uint8List toHash = new Uint8List.fromList(new List<int>()
      ..addAll(buffer.asBytes())
    // We also have to write a hash type (sigHashType is actually an unsigned char)
      ..add(0x000000ff & sigHashFlags));
    // Note that this is NOT reversed to ensure it will be signed correctly. If it were to be printed out
    // however then we would expect that it is IS reversed.
    Hash256 hash = new Hash256(crypto.doubleDigest(toHash));

    // Put the transaction back to how we found it.
    this.inputs = originalInputs;
    for (int i = 0; i < originalInputs.length; i++) {
      originalInputs[i].scriptSig = inputScripts[i];
      originalInputs[i].sequence = inputSequenceNumbers[i];
    }
    outputs = originalOutputs;
    return hash;
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeUintLE(buffer, version);
    writeVarInt(buffer, inputs.length);
    for(TransactionInput input in inputs)
      writeObject(buffer, input, pver);
    writeVarInt(buffer, outputs.length);
    for(TransactionOutput output in outputs)
      writeObject(buffer, output, pver);
    writeUintLE(buffer, lockTime);
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    version = readUintLE(reader);
    int nbInputs = readVarInt(reader);
    inputs = new List<TransactionInput>();
    for(int i = 0 ; i < nbInputs ; i++) {
      inputs.add(readObject(reader, new TransactionInput.empty(), pver));
    }
    int nbOutputs = readVarInt(reader);
    outputs = new List<TransactionOutput>();
    for(int i = 0 ; i < nbOutputs ; i++) {
      outputs.add(readObject(reader, new TransactionOutput.empty(), pver));
    }
    lockTime = readUintLE(reader);
  }
}








