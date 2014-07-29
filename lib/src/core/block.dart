part of dartcoin.core;

class Block extends Object with HashRepresentable, BitcoinSerialization {
  
  static const int BLOCK_VERSION = 1;
  
  static const int HEADER_SIZE = 80;

  /**
   * A constant shared by the entire network: how large in bytes a block is allowed to be. One day we may have to
   * upgrade everyone to change this, so Bitcoin can continue to grow. For now it exists as an anti-DoS measure to
   * avoid somebody creating a titanically huge but valid block and forcing everyone to download/store it forever.
   */
  static const int MAX_BLOCK_SIZE = 1 * 1000 * 1000;
  /**
   * A "sigop" is a signature verification operation. Because they're expensive we also impose a separate limit on
   * the number in a block to prevent somebody mining a huge block that has way more sigops than normal, so is very
   * expensive/slow to verify.
   */
  static const int MAX_BLOCK_SIGOPS = MAX_BLOCK_SIZE ~/ 50;
  
  static const int ALLOWED_TIME_DRIFT = 2 * 60 * 60; // Same value as official client.
  
  /** A value for difficultyTarget (nBits) that allows half of all possible hash solutions. Used in unit testing. */
  static const int EASIEST_DIFFICULTY_TARGET = 0x207fFFFF;
  
  Sha256Hash _hash;
  
  int _version;
  Sha256Hash _previous;
  Sha256Hash _merkle;
  int _timestamp;
  int _difficultyTarget;
  int _nonce;
  List<Transaction> _txs;
  
  int _height;
  
  Block({ Sha256Hash hash,
          Sha256Hash previousBlock,
          Sha256Hash merkleRoot,
          int timestamp,
          int difficultyTarget,
          int nonce: 0,
          List<Transaction> transactions,
          int height,
          int version: BLOCK_VERSION,
          NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _hash = hash;
    _previous = previousBlock != null ? previousBlock : Sha256Hash.ZERO_HASH;
    _merkle = merkleRoot;
    _timestamp = timestamp != null ? timestamp : new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _difficultyTarget = difficultyTarget != null ? difficultyTarget : EASIEST_DIFFICULTY_TARGET;
    _nonce = nonce;
    _txs = transactions != null ? transactions : new List<Transaction>();
    _height = height;
    _version = version;
    this.params = params;
  }
  
  // required for serialization
  Block._newInstance();
  
  /**
   * Deserialize a block.
   * 
   * Please note that when this block represents only a header, 
   * you must indicate the correct [length] or provide a [bytes] of correct length.
   * You can also use the [deserializeHeader()] constructor for deserializing headers. 
   */
  factory Block.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) =>  
          new BitcoinSerialization.deserialize(new Block._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, parent: parent);
  
  /**
   * Deserialize a block header.
   */
  factory Block.deserializeHeader(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) =>  
          new BitcoinSerialization.deserialize(new Block._newInstance(), bytes, length: HEADER_SIZE, lazy: lazy, retain: retain, params: params, parent: parent);
  
  int get version {
    _needInstance();
    return _version;
  }
  
  Sha256Hash get hash {
    if(_hash != null)
      return _hash;
    _hash = _calculateHash();
    return _hash;
  }
  
  Sha256Hash _calculateHash() {
    if(isCached)
      return new Sha256Hash(Utils.reverseBytes(Utils.doubleDigest(_serialization.sublist(0, HEADER_SIZE))));
    _needInstance();
    return new Sha256Hash(Utils.reverseBytes(Utils.doubleDigest(_serializeHeader())));
  }
  
  Sha256Hash get previousBlock {
    _needInstance();
    return _previous;
  }
  
  void set previousBlock(Sha256Hash previousBlock) {
    _needInstance(true);
    _previous = previousBlock;
  }
  
  Sha256Hash get merkleRoot {
    _needInstance();
    if(_merkle == null) {
      _needInstance(true);
      _merkle = _calculateMerkleRoot();
    }
    return _merkle;
  }
  
  void set merkleRoot(Sha256Hash merkleRoot) {
    _needInstance(true);
    _merkle = merkleRoot;
  }
  
  int get timestamp {
    _needInstance();
    return _timestamp;
  }
  
  void set timestamp(int timestamp) {
    _needInstance(true);
    _timestamp = timestamp;
  }
  
  DateTime get time => new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  
  void set time(DateTime time) {
    timestamp = time.millisecondsSinceEpoch ~/ 1000;
  }
  
  /**
   * The difficulty target. 
   * 
   * This is the same as the [bits] attribute; 
   */
  int get difficultyTarget {
    _needInstance();
    return _difficultyTarget;
  }
  
  BigInteger get difficultyTargetAsInteger => Utils.decodeCompactBits(difficultyTarget);
  
  void set difficultyTarget(int difficultyTarget) {
    _needInstance(true);
    _difficultyTarget = difficultyTarget;
  }
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  void set nonce(int nonce) {
    _needInstance(true);
    _nonce = nonce;
  }
  
  int get height {
    return _height;
  }
  
  void set height(int height) {
    _height = height;
  }
  
  List<Transaction> get transactions {
    _needInstance();
    return _txs == null ? null : new UnmodifiableListView(_txs);
  }
  
  void set transactions(List<Transaction> transactions) {
    _needInstance(true);
    for(Transaction tx in transactions)
      tx._parent = this;
    _txs = transactions;
    _merkle = null;
  }
  
  bool get isHeader {
    if(_serializationLength == HEADER_SIZE)
      return true;
    _needInstance();
    return _txs == null || _txs.isEmpty;
  }

  /**
   * The number that is one greater than the largest representable SHA-256
   * hash.
   */
  static final BigInteger _LARGEST_HASH = (BigInteger.ONE << 256);
  
  /**
   * Returns the work represented by this block.
   *
   * Work is defined as the number of tries needed to solve a block in the
   * average case. Consider a difficulty target that covers 5% of all possible
   * hash values. Then the work of the block will be 20. As the target gets
   * lower, the amount of work goes up.
   */
  BigInteger get work => _LARGEST_HASH / (difficultyTargetAsInteger + BigInteger.ONE);
  
  Block cloneAsHeader() {
    if(isCached) {
      Uint8List headerBytes = serialize().sublist(0, HEADER_SIZE);
      Uint8List cloneBytes = new Uint8List(HEADER_SIZE + 1);
      Utils.arrayCopy(headerBytes, 0, cloneBytes, 0, HEADER_SIZE);
      return new Block.deserialize(cloneBytes, length: HEADER_SIZE + 1);
    }
    _needInstance(true);
    Block b = new Block(
        hash: hash, 
        previousBlock: _previous,
        merkleRoot: _merkle,
        timestamp: _timestamp,
        difficultyTarget: _difficultyTarget,
        nonce: _nonce);
    b._serializationLength = HEADER_SIZE + 1;
    return b;
  }

  /** 
   * Adds a transaction to this block, with or without checking the sanity of doing so. 
   */
  void addTransaction(Transaction tx, [bool runSanityChecks = true]) {
    _needInstance(true);
    if (_txs == null) {
      _txs = new List<Transaction>();
    }
    tx._parent = this;
    if (runSanityChecks && transactions.length == 0 && !tx.isCoinbase)
      throw new Exception("Attempted to add a non-coinbase transaction as the first transaction: $tx");
    else if (runSanityChecks && transactions.length > 0 && tx.isCoinbase)
      throw new Exception("Attempted to add a coinbase transaction when there already is one: $tx");
    _txs.add(tx);
    // Force a recalculation next time the values are needed.
    _merkle = null;
  }
  
  Sha256Hash _calculateMerkleRoot() {
    _needInstance(true);
    // first add all tx hashes to the tree
    List<Uint8List> tree = new List<Uint8List>();
    for(Transaction tx in _txs) {
      tree.add(tx.hash.bytes);
    }
    // then complete the tree
    _buildMerkleTree(tree);
    return new Sha256Hash(tree.last);
  }
  
  static List<Uint8List> _buildMerkleTree(List<Uint8List> tree) {
    // The Merkle root is based on a tree of hashes calculated from the transactions:
    //
    //     root
    //      / \
    //   A      B
    //  / \    / \
    // t1 t2 t3 t4
    //
    // The tree is represented as a list: t1,t2,t3,t4,A,B,root where each
    // entry is a hash.
    //
    // The hashing algorithm is double SHA-256. The leaves are a hash of the serialized contents of the transaction.
    // The interior nodes are hashes of the concenation of the two child hashes.
    //
    // This structure allows the creation of proof that a transaction was included into a block without having to
    // provide the full block contents. Instead, you can provide only a Merkle branch. For example to prove tx2 was
    // in a block you can just provide tx2, the hash(tx1) and B. Now the other party has everything they need to
    // derive the root, which can be checked against the block header. These proofs aren't used right now but
    // will be helpful later when we want to download partial block contents.
    //
    // Note that if the number of transactions is not even the last tx is repeated to make it so (see
    // tx3 above). A tree with 5 transactions would look like this:
    //
    //         root
    //        /     \
    //       1        5
    //     /   \     / \
    //    2     3    4  4
    //  / \   / \   / \
    // t1 t2 t3 t4 t5 t5
    int levelOffset = 0; // Offset in the list where the currently processed level starts.
    // Step through each level, stopping when we reach the root (levelSize == 1).
    for (int levelSize = tree.length; levelSize > 1; levelSize = (levelSize + 1) ~/ 2) {
      // For each pair of nodes on that level:
      for (int left = 0; left < levelSize; left += 2) {
        // The right hand node can be the same as the left hand, in the case where we don't have enough
        // transactions.
        int right = min(left + 1, levelSize - 1);
        Uint8List leftHash  = Utils.reverseBytes(tree[levelOffset + left]);
        Uint8List rightHash = Utils.reverseBytes(tree[levelOffset + right]);
        tree.add(Utils.reverseBytes(Utils.doubleDigestTwoInputs(leftHash, rightHash)));
      }
      // Move to the next level.
      levelOffset += levelSize;
    }
    return tree;
  }

  /** Returns true if the hash of the block is OK (lower than difficulty target). */
  bool _checkProofOfWork(bool throwException) {
    // This part is key - it is what proves the block was as difficult to make as it claims
    // to be. Note however that in the context of this function, the block can claim to be
    // as difficult as it wants to be .... if somebody was able to take control of our network
    // connection and fork us onto a different chain, they could send us valid blocks with
    // ridiculously easy difficulty and this function would accept them.
    //
    // To prevent this attack from being possible, elsewhere we check that the difficultyTarget
    // field is of the right value. This requires us to have the preceeding blocks.
    BigInteger target = difficultyTargetAsInteger;
    if (target <= BigInteger.ZERO || target > params.proofOfWorkLimit)
      throw new VerificationException("Difficulty target is bad: $target");

    BigInteger h = hash.toBigInteger();
    if(h > target) {
      // Proof of work check failed!
      if(throwException)
        throw new VerificationException("Hash is higher than target: $hash vs ${target.toString(16)}");
      else
        return false;
    }
    return true;
  }

  void _checkTimestamp() {
    _needInstance();
    // Allow injection of a fake clock to allow unit testing.
    int currentTime = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if(_timestamp > currentTime + ALLOWED_TIME_DRIFT)
      throw new VerificationException("Block too far in future");
  }

  void _checkSigOps() {
    // Check there aren't too many signature verifications in the block. This is an anti-DoS measure, see the
    // comments for MAX_BLOCK_SIGOPS.
    int sigOps = 0;
    for(Transaction tx in _txs)
      sigOps += tx.sigOpCount;
    if(sigOps > MAX_BLOCK_SIGOPS)
      throw new VerificationException("Block had too many Signature Operations");
  }

  void _checkMerkleRoot() {
    Sha256Hash calculatedRoot = _calculateMerkleRoot();
    if (calculatedRoot != _merkle) {
      throw new VerificationException("Merkle hashes do not match: $calculatedRoot vs $_merkle");
    }
  }

  void _checkTransactions() {
    // The first transaction in a block must always be a coinbase transaction.
    if (!_txs[0].isCoinbase)
      throw new VerificationException("First tx is not coinbase");
    // The rest must not be.
    for (int i = 1; i < transactions.length; i++) {
      if (_txs[i].isCoinbase)
        throw new VerificationException("TX $i is coinbase when it should not be.");
    }
  }

  /**
   * Checks the block data to ensure it follows the rules laid out in the network parameters. Specifically,
   * throws an exception if the proof of work is invalid, or if the timestamp is too far from what it should be.
   * This is <b>not</b> everything that is required for a block to be valid, only what is checkable independent
   * of the chain and without a transaction index.
   *
   * @throws VerificationException
   */
  void verifyHeader([bool checkTimestamp = false]) {
    // Prove that this block is OK. It might seem that we can just ignore most of these checks given that the
    // network is also verifying the blocks, but we cannot as it'd open us to a variety of obscure attacks.
    //
    // Firstly we need to ensure this block does in fact represent real work done. If the difficulty is high
    // enough, it's probably been done by the network.
    _needInstance();
    _checkProofOfWork(true);
    if(checkTimestamp)
      _checkTimestamp();
  }

  /**
   * Checks the block contents
   *
   * @throws VerificationException
   */
  void verifyTransactions() {
    // Now we need to check that the body of the block actually matches the headers. The network won't generate
    // an invalid block, but if we didn't validate this then an untrusted man-in-the-middle could obtain the next
    // valid block from the network and simply replace the transactions in it with their own fictional
    // transactions that reference spent or non-existant inputs.
    if(_txs == null || _txs.isEmpty)
      throw new VerificationException("Block had no transactions");
    _needInstance();
    if(this.serializationLength > MAX_BLOCK_SIZE)
      throw new VerificationException("Block larger than MAX_BLOCK_SIZE");
    _checkTransactions();
    _checkMerkleRoot();
    _checkSigOps();
    for(Transaction tx in _txs)
      tx.verify();
  }

  /**
   * Verifies both the header and that the transactions hash to the merkle root.
   */
  void verify([bool checkTimestamp = false]) {
    verifyHeader(checkTimestamp);
    verifyTransactions();
  }

  /**
   * <p>Finds a value of nonce that makes the blocks hash lower than the difficulty target. This is called mining, but
   * solve() is far too slow to do real mining with. It exists only for unit testing purposes.
   *
   * <p>This can loop forever if a solution cannot be found solely by incrementing nonce. It doesn't change
   * extraNonce.</p>
   */
  void solve() {
    _needInstance();
    while(true) {
      // Is our proof of work valid yet?
      if(_checkProofOfWork(false))
        return;
      // No, so increment the nonce and try again.
      _needInstance(true);
      _nonce++;
    }
  }
  
  Uint8List _serializeHeader() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesLE(_version, 4))
      ..addAll(_previous.serialize())
      ..addAll(merkleRoot.serialize()) // the getter is used intentionally here 
      ..addAll(Utils.uintToBytesLE(_timestamp, 4))
      ..addAll(Utils.uintToBytesLE(_difficultyTarget, 4))
      ..addAll(Utils.uintToBytesLE(_nonce, 4)));
  }
  
  Uint8List _serialize() {
    List<int> result = new List();
    result.addAll(_serializeHeader());
    if(isHeader)
      result.add(0);
    else {
      result.addAll(new VarInt(_txs.length).serialize());
      _txs.forEach((tx) => result.addAll(tx.serialize()));
    }
    return new Uint8List.fromList(result);
  }
  
  /**
   * Returns the header size
   */
  int _deserializeHeader(Uint8List bytes) {
    _version = Utils.bytesToUintLE(bytes.sublist(0, 4));
    _previous = new Sha256Hash.deserialize(bytes.sublist(4, 36));
    _merkle = new Sha256Hash.deserialize(bytes.sublist(36, 68));
    _timestamp = Utils.bytesToUintLE(bytes.sublist(68), 4);
    _difficultyTarget = Utils.bytesToUintLE(bytes.sublist(72), 4);
    _nonce = Utils.bytesToUintLE(bytes.sublist(76), 4);
    return HEADER_SIZE;
  }
  
  /**
   * Returns the serialization length after the header (varint + sum of txs)
   */
  int _deserializeTransactions(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    List<Transaction> txs = new List<Transaction>();
    VarInt nbTx = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbTx.serializationLength;
    for(int i = 0 ; i < nbTx.value ; i++) {
      Transaction tx = new Transaction.deserialize(bytes.sublist(offset), lazy: lazy, retain: retain, params: params);
      offset += tx.serializationLength;
      txs.add(tx);
    }
    _txs = txs.length > 0 ? txs : null;
    return offset;
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    // parse header
    int offset = _deserializeHeader(bytes);
    // check if this block is only a header or a full block
    if(_serializationLength == HEADER_SIZE || bytes.length == HEADER_SIZE)
      return offset;
    // parse transactions
    offset += _deserializeTransactions(bytes.sublist(offset), lazy, retain);
    return offset;
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) => _calculateSerializationLength(bytes);
  
  static int _calculateSerializationLength(Uint8List bytes) {
    int offset = HEADER_SIZE;
    // transactions
    VarInt nbTx = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbTx.serializationLength;
    for(int i = 0 ; i < nbTx.value ; i++)
      offset += Transaction._calculateSerializationLength(bytes.sublist(offset));
    return offset;
  }
  
  @override
  void _needInstance([bool clearCache = false]) {
    super._needInstance(clearCache);
    if(clearCache)
      _hash = null;
  }
}





