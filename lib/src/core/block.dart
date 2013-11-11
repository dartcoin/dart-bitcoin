part of dartcoin;

class Block {
  
  Sha256Hash _hash;
  
  final int version = 0x01000000;
  Sha256Hash _previous;
  Sha256Hash _merkle;
  int _timestamp;
  int _bits;
  int _nonce;
  List<Transaction> _txs;
  
  Block({ Sha256Hash hash,
          Sha256Hash previousBlock,
          Sha256Hash merkleRoot,
          int timestamp,
          int bits,
          int nonce,
          List<Transaction> transactions}) {
    _hash = hash;
    _previous = previousBlock;
    _merkle = merkleRoot;
    _timestamp = timestamp;
    _bits = bits;
    _nonce = nonce;
    _txs = transactions;
    if(hash == null) {
      //TODO calculate hash
    }
  }
  
  Sha256Hash get hash {
    if(_hash == null) {
      _calculateHash();
    }
    return _hash;
  }
  
  void set hash(Sha256Hash hash) {
    _hash = hash;
  }
  
  Sha256Hash get previousBlock {
    return _previous;
  }
  
  void set previousBlock(Sha256Hash previousBlock) {
    _previous = previousBlock;
    _hash = null;
  }
  
  Sha256Hash get merkleRoot {
    if(_merkle == null) {
      _calculateMerkleRoot();
    }
    return _merkle;
  }
  
  void set merkleRoot(Sha256Hash merkleRoot) {
    _merkle = merkleRoot;
    _hash = null;
  }
  
  int get timestamp {
    return _timestamp;
  }
  
  void set timestamp(int timestamp) {
    _timestamp = timestamp;
    _hash = null;
  }
  
  int get bits {
    return _bits;
  }
  
  void set bits(int bits) {
    _bits = bits;
    _hash = null;
  }
  
  int get nonce {
    return _nonce;
  }
  
  void set nonce(int nonce) {
    _nonce = nonce;
    _hash = null;
  }
  
  List<Transaction> get transactions {
    return _txs;
  }
  
  void set transactions(List<Transaction> transactions) {
    _txs = transactions;
    _merkle = null;
  }
  
  void _calculateHash() {
    _hash = Sha256Hash.createDouble(_encodeHeader());
  }
  
  void _calculateMerkleRoot() {
    List<Sha256Hash> tree = _buildMerkleTree();
    merkleRoot = tree.last;
  }
  
  List<Sha256Hash> _buildMerkleTree() {
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
    List<Sha256Hash> tree = new List();
    // Start by adding all the hashes of the transactions as leaves of the tree.
    for(Transaction tx in transactions) {
      tree.add(tx.hash);
    }
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
        Uint8List concat = leftHash.bytes;
        concat.addAll(rightHash.bytes);
        tree.add(Sha256Hash.createDouble(concat));
      }
      // Move to the next level.
      levelOffset += levelSize;
    }
    return tree;
  }
  
  Uint8List _encodeHeader() {
    Uint8List result = new List();
    result.addAll(Utils.intToBytesBE(version, 4));
    result.addAll(previousBlock.bytes);
    result.addAll(merkleRoot.bytes);
    result.addAll(Utils.intToBytesBE(timestamp, 4));
    result.addAll(Utils.intToBytesBE(bits, 4));
    result.addAll(Utils.intToBytesBE(nonce, 4));
    return result;
  }
  
  Uint8List encode() {
    Uint8List result = new List();
    result.addAll(_encodeHeader());
    result.addAll(new VarInt(transactions.length).encode());
    for(Transaction tx in transactions) {
      result.addAll(tx.encode());
    }
    return result;
  }
}





