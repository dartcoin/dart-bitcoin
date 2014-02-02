part of dartcoin.core;

class Block extends Object with BitcoinSerialization {
  
  static const int HEADER_SIZE = 80;
  
  Sha256Hash _hash;
  
  int _version = 0x01000000;
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
          int height}) {
    _hash = hash;
    _previous = previousBlock;
    _merkle = merkleRoot;
    _timestamp = timestamp;
    _bits = bits;
    _nonce = nonce;
    _txs = transactions;
    _height = height;
  }
  
  factory Block.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new Block(), bytes, length: length, lazy: lazy);
  
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
    _needInstance();
    _hash = hash;
  }
  
  Sha256Hash get previousBlock {
    _needInstance();
    return _previous;
  }
  
  void set previousBlock(Sha256Hash previousBlock) {
    _needInstance();
    _previous = previousBlock;
    _hash = null;
  }
  
  Sha256Hash get merkleRoot {
    _needInstance();
    if(_merkle == null) {
      _calculateMerkleRoot();
    }
    return _merkle;
  }
  
  void set merkleRoot(Sha256Hash merkleRoot) {
    _needInstance();
    _merkle = merkleRoot;
    _hash = null;
  }
  
  int get timestamp {
    _needInstance();
    return _timestamp;
  }
  
  void set timestamp(int timestamp) {
    _needInstance();
    _timestamp = timestamp;
    _hash = null;
  }
  
  int get bits {
    _needInstance();
    return _bits;
  }
  
  void set bits(int bits) {
    _needInstance();
    _bits = bits;
    _hash = null;
  }
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  void set nonce(int nonce) {
    _needInstance();
    _nonce = nonce;
    _hash = null;
  }
  
  int get height {
    return _height;
  }
  
  void set height(int height) {
    _height = height;
  }
  
  List<Transaction> get transactions {
    _needInstance();
    return _txs;
  }
  
  void set transactions(List<Transaction> transactions) {
    _needInstance();
    _txs = transactions;
    _merkle = null;
  }
  
  bool get isHeader {
    _needInstance();
    return transactions == null;
  }
  
  void _calculateHash() {
    _needInstance();
    _hash = Sha256Hash.doubleDigest(_serializeHeader());
  }
  
  void _calculateMerkleRoot() {
    _needInstance();
    // first add all tx hashes to the tree
    List<Sha256Hash> tree = new List();
    for(Transaction tx in transactions) {
      tree.add(tx.hash);
    }
    // then complete the tree
    _buildMerkleTree(tree);
    merkleRoot = tree.last;
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
  
  Uint8List _serializeHeader() {
    List<int> result = new List();
    result.addAll(Utils.uintToBytesBE(version, 4));
    result.addAll(previousBlock.bytes);
    result.addAll(merkleRoot.bytes);
    result.addAll(Utils.uintToBytesBE(timestamp, 4));
    result.addAll(Utils.uintToBytesBE(bits, 4));
    result.addAll(Utils.uintToBytesBE(nonce, 4));
    return new Uint8List.fromList(result);
  }
  
  void _deserializeHeader(Uint8List bytes) {
    _version = Utils.bytesToUintBE(bytes.sublist(0, 4));
    _previous = new Sha256Hash(bytes.sublist(4, 36));
    _merkle = new Sha256Hash(bytes.sublist(36, 68));
    _timestamp = Utils.bytesToUintBE(bytes.sublist(68), 4);
    _bits = Utils.bytesToUintBE(bytes.sublist(72), 4);
    _nonce = Utils.bytesToUintBE(bytes.sublist(76), 4);
  }
  
  Uint8List _serialize() {
    List<int> result = new List();
    result.addAll(_serializeHeader());
    if(!isHeader) {
      result.addAll(new VarInt(transactions.length).serialize());
      for(Transaction tx in transactions) {
        result.addAll(tx.serialize());
      }
    }
    return new Uint8List.fromList(result);
  }
  
  void _deserialize(Uint8List bytes) {
    _deserializeHeader(bytes);
    // parse transactions
    int offset = HEADER_SIZE;
    _txs = new List<Transaction>();
    VarInt nbTx = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbTx.serializationLength;
    for(int i = 0 ; i < nbTx.value ; i++) {
      Transaction tx = new Transaction.deserialize(bytes.sublist(offset));
      offset += tx.serializationLength;
      _txs.add(tx);
    }
    _serializationLength = offset;
  }
}





