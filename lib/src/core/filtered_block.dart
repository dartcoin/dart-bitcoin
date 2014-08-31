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
    if(header == null || merkleTree == null)
      throw new ArgumentError("header or merkleTree is null");
    _header = header;
    _merkle = merkleTree;
    _hashes = hashes;
    this.params = header.params;
  }
  
  // required for serialization
  FilteredBlock._newInstance();
  
  factory FilteredBlock.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, BitcoinSerialization parent}) => 
          new BitcoinSerialization.deserialize(new FilteredBlock._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, parent: parent);
  
  Block get header {
    _needInstance();
    if(!_header.isHeader)
      _header.cloneAsHeader();
    return _header;
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
    if(_hashes == null) {
      _needInstance();
      List<Sha256Hash> hashes = new List<Sha256Hash>();
      if(_header.merkleRoot == _merkle.getTxnHashAndMerkleRoot(hashes)) {
        _hashes = hashes;
      } else {
        throw new Exception("Merkle root of block header does not match merkle root of partial merkle tree.");
      }
    }
    return new UnmodifiableListView(_hashes);
  }
  
  // the following two methods are used to fill this block with relevant transactions
  
  /**
   * Provide this FilteredBlock with a transaction which is in its merkle tree
   * @returns false if the tx is not relevant to this FilteredBlock
   */
  bool provideTransaction(Transaction tx) {
    _needInstance();
    if(_txs == null) 
      _txs = new Map<Sha256Hash, Transaction>();
    Sha256Hash hash = tx.hash;
    if(_hashes.contains(hash)) {
      _txs[hash] = tx;
      return true;
    } else
      return false;
  }
  
  /**
   * Gets the set of transactions which were provided using provideTransaction() which match in getTransactionHashes()
   */
  Map<Sha256Hash, Transaction> get associatedTransactions {
    _needInstance();
    return new UnmodifiableMapView(_txs);
  }
  
  // serialization

  @override
  Uint8List _serialize() {
    List<int> result = new List<int>();
    if(_header.isHeader)
      result.addAll(_header.serialize());
    else
      result.addAll(_header.cloneAsHeader().serialize());
    result.addAll(_merkle.serialize());
    return new Uint8List.fromList(result);
  }

  @override
  void _deserialize() {
    _header = _readObject(new Block._newInstance(), length: Block.HEADER_SIZE);
    _merkle = _readObject(new PartialMerkleTree._newInstance());
  }

  @override
  void _deserializeLazy() {
    _serializationCursor += Block.HEADER_SIZE;
    _readObject(new PartialMerkleTree._newInstance(), lazy: true);
  }
  
}





