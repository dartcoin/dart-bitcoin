part of dartcoin.core;

class Block extends Object with BitcoinSerialization {
  
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
  
  Sha256Hash _hash;
  
  int _version;
  Sha256Hash _previous;
  Sha256Hash _merkle;
  int _timestamp;
  int _bits;
  int _nonce;
  List<Transaction> _txs;
  
  int _height;
  
  Block({ Sha256Hash hash,
          Sha256Hash previousBlock,
          Sha256Hash merkleRoot,
          int timestamp,
          int bits,
          int nonce,
          List<Transaction> transactions,
          int height,
          int version: BLOCK_VERSION,
          NetworkParameters params: NetworkParameters.MAIN_NET}) {
    _hash = hash;
    _previous = previousBlock;
    _merkle = merkleRoot;
    _timestamp = timestamp;
    _bits = bits;
    _nonce = nonce;
    _txs = transactions;
    _height = height;
    _version = version;
    this.params = params;
  }
  
  factory Block.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) =>  
          new BitcoinSerialization.deserialize(new Block(), bytes, length: length, lazy: lazy, params: params);
  
  int get version {
    _needInstance();
    return _version;
  }
  
  Sha256Hash get hash {
    _needInstance();
    if(_hash == null) {
      _calculateHash();
    }
    return _hash;
  }
  
  void set hash(Sha256Hash hash) {
    _needInstance(true);
    _hash = hash;
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
      _calculateMerkleRoot();
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
  
  int get bits {
    _needInstance();
    return _bits;
  }
  
  void set bits(int bits) {
    _needInstance(true);
    _bits = bits;
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
    return new UnmodifiableListView(_txs);
  }
  
  void set transactions(List<Transaction> transactions) {
    _needInstance(true);
    _txs = transactions;
    _merkle = null;
  }
  
  bool get isHeader {
    _needInstance();
    return _txs == null;
  }
  
  Block cloneAsHeader() {
    if(_isSerialized) {
      List<int> bytes = serialize().sublist(0, 80);
      bytes.add(0);
      return new Block.deserialize(bytes, length: HEADER_SIZE + 1);
    }
    Block b = new Block(
        hash: hash, 
        previousBlock: previousBlock,
        merkleRoot: merkleRoot,
        timestamp: timestamp,
        bits: bits,
        nonce: nonce);
    b._serializationLength = HEADER_SIZE + 1;
    return b;
  }

  /** 
   * Adds a transaction to this block, with or without checking the sanity of doing so. 
   */
  void addTransaction(Transaction t, [bool runSanityChecks = true]) {
    _needInstance(true);
    if (_txs == null) {
      _txs = new List<Transaction>();
    }
    t.parentBlock = this;
    if (runSanityChecks && transactions.length == 0 && !t.isCoinbase)
      throw new Exception("Attempted to add a non-coinbase transaction as the first transaction: $t");
    else if (runSanityChecks && transactions.length > 0 && t.isCoinbase)
      throw new Exception("Attempted to add a coinbase transaction when there already is one: $t");
    _txs.add(t);
    // Force a recalculation next time the values are needed.
    _merkle = null;
  }
  
  void _calculateHash() {
    _needInstance(true);
    _hash = Sha256Hash.doubleDigest(_serializeHeader());
  }
  
  void _calculateMerkleRoot() {
    _needInstance(true);
    // first add all tx hashes to the tree
    List<Sha256Hash> tree = new List();
    for(Transaction tx in transactions) {
      tree.add(tx.hash);
    }
    // then complete the tree
    _buildMerkleTree(tree);
    _merkle = tree.last;
  }
  
  static List<Sha256Hash> _buildMerkleTree(List<Sha256Hash> tree) {
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
        Sha256Hash leftHash  = tree[levelOffset + left];
        Sha256Hash rightHash = tree[levelOffset + right];
        Uint8List concat = new Uint8List(leftHash.bytes.length + rightHash.bytes.length);
        concat.replaceRange(0, leftHash.bytes.length, leftHash.bytes);
        concat.replaceRange(leftHash.bytes.length, concat.length, rightHash.bytes);
        tree.add(Sha256Hash.doubleDigest(concat));
      }
      // Move to the next level.
      levelOffset += levelSize;
    }
    return tree;
  }
  
  Uint8List _serializeHeader() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesBE(version, 4))
      ..addAll(previousBlock.bytes)
      ..addAll(merkleRoot.bytes)
      ..addAll(Utils.uintToBytesBE(timestamp, 4))
      ..addAll(Utils.uintToBytesBE(bits, 4))
      ..addAll(Utils.uintToBytesBE(nonce, 4)));
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
    _version = Utils.bytesToUintBE(bytes.sublist(0, 4));
    _previous = new Sha256Hash(bytes.sublist(4, 36));
    _merkle = new Sha256Hash(bytes.sublist(36, 68));
    _timestamp = Utils.bytesToUintBE(bytes.sublist(68), 4);
    _bits = Utils.bytesToUintBE(bytes.sublist(72), 4);
    _nonce = Utils.bytesToUintBE(bytes.sublist(76), 4);
    return HEADER_SIZE;
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = _deserializeHeader(bytes);
    // parse transactions
    _txs = new List<Transaction>();
    VarInt nbTx = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbTx.size;
    for(int i = 0 ; i < nbTx.value ; i++) {
      Transaction tx = new Transaction.deserialize(bytes.sublist(offset));
      offset += tx.serializationLength;
      _txs.add(tx);
    }
    return offset;
  }
  
  @override
  void _needInstance([bool clearCache = false]) {
    super._needInstance(clearCache);
    _hash = null;
  }
}





