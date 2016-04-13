part of dartcoin.core;

class FilteredBlock extends BitcoinSerializable {
  /** The protocol version at which Bloom filtering started to be supported. */
  static const int MIN_PROTOCOL_VERSION = 70000;
  
  Block header;
  PartialMerkleTree merkleTree;

  // cached list of tx hashes
  List<Hash256> _hashes;
  Map<Hash256, Transaction> _txs;
  
  FilteredBlock(Block this.header, PartialMerkleTree this.merkleTree) {
    if(header == null || merkleTree == null)
      throw new ArgumentError("header or merkleTree is null");
  }
  
  /// Create an empty instance.
  FilteredBlock.empty();
  
  /**
   * Number of transactions in this block, before it was filtered.
   */
  int get transactionCount => merkleTree.transactionCount;
  
  List<Hash256> get transactionHashes {
    if(_hashes == null) {
      List<Hash256> hashes = new List<Hash256>();
      if(header.merkleRoot == merkleTree.getTxnHashAndMerkleRoot(hashes)) {
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
    _txs = _txs ?? new Map<Hash256, Transaction>();
    Hash256 hash = tx.hash;
    if(_hashes.contains(hash)) {
      _txs[hash] = tx;
      return true;
    } else {
      return false;
    }
  }
  
  /**
   * Gets the set of transactions which were provided using provideTransaction() which match in getTransactionHashes()
   */
  Map<Hash256, Transaction> get associatedTransactions {
    return new UnmodifiableMapView(_txs);//TODO something changed in the collection package
  }
  
  // serialization

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    if(header.isHeader) {
      writeObject(buffer, header, pver);
    } else {
      writeObject(buffer, header.cloneAsHeader(), pver);
    }
    writeObject(buffer, merkleTree, pver);
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    header = readObject(reader, new Block.empty(), pver);
    merkleTree = readObject(reader, new PartialMerkleTree.empty(), pver);
  }
}





