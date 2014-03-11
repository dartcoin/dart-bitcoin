part of dartcoin.core;

class FilteredBlock extends Object with BitcoinSerialization {
  /** The protocol version at which Bloom filtering started to be supported. */
  static const int MIN_PROTOCOL_VERSION = 70000;
  
  Block _header;
  
  PartialMerkleTree _merkle;
  // cached list of tx hashes
  List<Sha256Hash> _hashes;
  
  Map<Sha256Hash, Transaction> _txs;
  
  FilteredBlock(Block header, PartialMerkleTree merkleTree, [List<Sha256Hash> hashes]) {
    _header = header;
    _merkle = merkleTree;
    _hashes = hashes;
  }
  
  factory FilteredBlock.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) => 
          new BitcoinSerialization.deserialize(new FilteredBlock(null, null), bytes, length: length, lazy: lazy, params: params);
  
  Block get header {
    _needInstance();
    return _header.cloneAsHeader();
  }
  
  Sha256Hash get hash {
    _needInstance();
    return _header.hash;
  }
  
  PartialMerkleTree get merkleTree {
    _needInstance();
    return _merkle;
  }
  
  /**
   * Number of transactions in this block, before it was filtered.
   */
  int get transactionCount => merkleTree.transactionCount;
  
  List<Sha256Hash> get transactionHashes {
    if(_hashes != null) return _hashes;
    _needInstance();
    List<Sha256Hash> hashes = new List<Sha256Hash>();
    if(_header.merkleRoot == _merkle.getTxnHashAndMerkleRoot(hashes)) {
      _hashes = hashes;
      return new UnmodifiableListView(_hashes);
    }
    throw new Exception("Merkle root of block header does not match merkle root of partial merkle tree.");
  }
  
  // the following two methods are used to fill this block with relevant transactions
  
  /**
   * Provide this FilteredBlock with a transaction which is in its merkle tree
   * @returns false if the tx is not relevant to this FilteredBlock
   */
  bool provideTransaction(Transaction tx) {
    _needInstance();
    if(_txs == null) _txs = new Map<Sha256Hash, Transaction>();
    Sha256Hash hash = tx.hash;
    if (_hashes.contains(hash)) {
      _txs[hash] = tx;
      return true;
    } else
      return false;
  }
  
  /** Gets the set of transactions which were provided using provideTransaction() which match in getTransactionHashes() */
  Map<Sha256Hash, Transaction> get associatedTransactions {
    _needInstance();
    return new UnmodifiableMapView(_txs);
  }
  
  // serialization
  
  Uint8List _serialize() {
    List<int> result = new List<int>();
    if(_header.isHeader)
      result.addAll(_header.serialize());
    else
      result.addAll(_header.cloneAsHeader().serialize());
    result.addAll(_merkle.serialize());
    return new Uint8List.fromList(result);
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    _header = new Block.deserialize(bytes, lazy: false);
    offset += _header.serializationLength;
    _merkle = new PartialMerkleTree.deserialize(bytes.sublist(offset), lazy: false);
    offset += _merkle.serializationLength;
    return offset;
  }
  
}





