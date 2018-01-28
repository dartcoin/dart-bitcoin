part of bitcoin.core;

class Block extends BlockHeader {
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

  List<Transaction> transactions;

  int height;

  Block(
      {Hash256 hash,
      int version: BLOCK_VERSION,
      Hash256 previousBlock,
      Hash256 merkleRoot,
      int timestamp,
      int difficultyTarget,
      int nonce: 0,
      List<Transaction> this.transactions,
      int this.height})
      : super._header(
            hash, version, previousBlock, merkleRoot, timestamp, difficultyTarget, nonce) {
    transactions = transactions ?? new List<Transaction>();
  }

  Block.fromHeader(BlockHeader header)
      : this(
            hash: header.hash,
            version: header.version,
            previousBlock: header.previousBlock,
            merkleRoot: header.merkleRoot,
            timestamp: header.timestamp,
            difficultyTarget: header.difficultyTarget,
            nonce: header.nonce);

  factory Block.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new Block.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }

  /// Create an empty instance.
  Block.empty() : super.empty();

  bool get hasTransactions {
    return transactions != null && transactions.isNotEmpty;
  }

  /**
   * The number that is one greater than the largest representable SHA-256
   * hash.
   */
  static final BigInteger _LARGEST_HASH = (BigInteger.ONE << 256);

  BlockHeader cloneAsHeader() => new BlockHeader(
      hash: _hash,
      previousBlock: previousBlock,
      merkleRoot: merkleRoot,
      timestamp: timestamp,
      difficultyTarget: difficultyTarget,
      nonce: nonce);

  /** 
   * Adds a transaction to this block, with or without checking the sanity of doing so. 
   */
  void addTransaction(Transaction tx, [bool runSanityChecks = true]) {
    if (transactions == null) {
      transactions = new List<Transaction>();
    }
    if (runSanityChecks && transactions.length == 0 && !tx.isCoinbase)
      throw new Exception(
          "Attempted to add a non-coinbase transaction as the first transaction: $tx");
    else if (runSanityChecks && transactions.length > 0 && tx.isCoinbase)
      throw new Exception("Attempted to add a coinbase transaction when there already is one: $tx");
    transactions.add(tx);
    // Force a recalculation next time the values are needed.
    merkleRoot = null;
  }

  Hash256 calculateMerkleRoot() {
    // first add all tx hashes to the tree
    List<Uint8List> tree = new List<Uint8List>();
    for (Transaction tx in transactions) {
      tree.add(tx.hash.asBytes());
    }
    // then complete the tree
    _buildMerkleTree(tree);
    merkleRoot = new Hash256(tree.last);
    return merkleRoot;
  }

  //TODO do this somewhere else
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
    // The interior nodes are hashes of the concatenation of the two child hashes.
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
        Uint8List leftHash = utils.reverseBytes(tree[levelOffset + left]);
        Uint8List rightHash = utils.reverseBytes(tree[levelOffset + right]);
        tree.add(utils.reverseBytes(crypto.doubleDigestTwoInputs(leftHash, rightHash)));
      }
      // Move to the next level.
      levelOffset += levelSize;
    }
    return tree;
  }

  /** Returns true if the hash of the block is OK (lower than difficulty target). */
  bool _checkProofOfWork(NetworkParameters params, bool throwException) {
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

    BigInteger h = hash.asBigInteger();
    if (h > target) {
      // Proof of work check failed!
      if (throwException)
        throw new VerificationException(
            "Hash is higher than target: $hash vs ${target.toString(16)}");
      else
        return false;
    }
    return true;
  }

  void _checkTimestamp() {
    // Allow injection of a fake clock to allow unit testing.
    int currentTime = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (timestamp > currentTime + ALLOWED_TIME_DRIFT)
      throw new VerificationException("Block too far in future");
  }

  void _checkSigOps() {
    // Check there aren't too many signature verifications in the block. This is an anti-DoS measure, see the
    // comments for MAX_BLOCK_SIGOPS.
    int sigOps = 0;
    for (Transaction tx in transactions) sigOps += tx.sigOpCount;
    if (sigOps > MAX_BLOCK_SIGOPS)
      throw new VerificationException("Block had too many Signature Operations");
  }

  void _checkMerkleRoot() {
    Hash256 calculatedRoot = calculateMerkleRoot();
    if (calculatedRoot != merkleRoot) {
      throw new VerificationException("Merkle hashes do not match: $calculatedRoot vs $merkleRoot");
    }
  }

  void _checkTransactions() {
    // The first transaction in a block must always be a coinbase transaction.
    if (!transactions[0].isCoinbase) throw new VerificationException("First tx is not coinbase");
    // The rest must not be.
    for (int i = 1; i < transactions.length; i++) {
      if (transactions[i].isCoinbase)
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
  void verifyHeader(NetworkParameters params, [bool checkTimestamp = false]) {
    // Prove that this block is OK. It might seem that we can just ignore most of these checks given that the
    // network is also verifying the blocks, but we cannot as it'd open us to a variety of obscure attacks.
    //
    // Firstly we need to ensure this block does in fact represent real work done. If the difficulty is high
    // enough, it's probably been done by the network.
    _checkProofOfWork(params, true);
    if (checkTimestamp) _checkTimestamp();
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
    if (transactions == null || transactions.isEmpty)
      throw new VerificationException("Block had no transactions");
    if (bitcoinSerializedBytes(0).length > MAX_BLOCK_SIZE)
      throw new VerificationException("Block larger than MAX_BLOCK_SIZE");
    _checkTransactions();
    _checkMerkleRoot();
    _checkSigOps();
    for (Transaction tx in transactions) tx.verify();
  }

  /**
   * Verifies both the header and that the transactions hash to the merkle root.
   */
  void verify(NetworkParameters params, [bool checkTimestamp = false]) {
    verifyHeader(params, checkTimestamp);
    verifyTransactions();
  }

  /**
   * <p>Finds a value of nonce that makes the blocks hash lower than the difficulty target. This is called mining, but
   * solve() is far too slow to do real mining with. It exists only for unit testing purposes.
   *
   * <p>This can loop forever if a solution cannot be found solely by incrementing nonce. It doesn't change
   * extraNonce.</p>
   */
  void solve(NetworkParameters params) {
    while (true) {
      // Is our proof of work valid yet?
      if (_checkProofOfWork(params, false)) return;
      // No, so increment the nonce and try again.
      nonce++;
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != Block) return false;
    if (identical(this, other)) return true;
    return hash == other.hash;
  }

  @override
  int get hashCode => (Block).hashCode ^ hash.hashCode;

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    // serialize header
    super.bitcoinSerialize(buffer, pver);
    if (!hasTransactions) {
      buffer.addByte(0);
    } else {
      writeVarInt(buffer, transactions.length);
      for (Transaction tx in transactions) writeObject(buffer, tx, pver);
    }
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    // deserialize header
    super.bitcoinDeserialize(reader, pver);
    _deserializeTransactions(reader, pver);
  }

  void _deserializeTransactions(bytes.Reader reader, int pver) {
    List<Transaction> txs = new List<Transaction>();
    int nbTx = readVarInt(reader);
    for (int i = 0; i < nbTx; i++) {
      Transaction tx = readObject(reader, new Transaction.empty(), pver);
      txs.add(tx);
    }
    transactions = txs.length > 0 ? txs : null;
  }
}
