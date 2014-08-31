part of dartcoin.core;

/**
 * <p>A data structure that contains proofs of block inclusion for one or more transactions, in an efficient manner.</p>
 *
 * <p>The encoding works as follows: we traverse the tree in depth-first order, storing a bit for each traversed node,
 * signifying whether the node is the parent of at least one matched leaf txid (or a matched txid itself). In case we
 * are at the leaf level, or this bit is 0, its merkle node hash is stored, and its children are not explored further.
 * Otherwise, no hash is stored, but we recurse into both (or the only) child branch. During decoding, the same
 * depth-first traversal is performed, consuming bits and hashes as they were written during encoding.</p>
 *
 * <p>The serialization is fixed and provides a hard guarantee about the encoded size,
 * <tt>SIZE <= 10 + ceil(32.25*N)</tt> where N represents the number of leaf nodes of the partial tree. N itself
 * is bounded by:</p>
 *
 * <p>
 * N <= total_transactions<br>
 * N <= 1 + matched_transactions*tree_height
 * </p>
 *
 * <p><pre>The serialization format:
 *  - uint32     total_transactions (4 bytes)
 *  - varint     number of hashes   (1-3 bytes)
 *  - uint256[]  hashes in depth-first order (<= 32*N bytes)
 *  - varint     number of bytes of flag bits (1-3 bytes)
 *  - Uint8List     flag bits, packed per 8 in a byte, least significant bit first (<= 2*N-1 bits)
 * The size constraints follow from this.</pre></p>
 */
class PartialMerkleTree extends Object with BitcoinSerialization {
    // the total number of transactions in the block
    int _transactionCount;

    // node-is-parent-of-matched-txid bits
    Uint8List _matchedChildBits;

    // txids and internal hashes
    List<Sha256Hash> _hashes;
    
    PartialMerkleTree( { int transactionCount,
                         Uint8List matchedChildBits,
                         List<Sha256Hash> hashes,
                         NetworkParameters params: NetworkParameters.MAIN_NET}) {
      _transactionCount = transactionCount;
      _matchedChildBits = matchedChildBits;
      _hashes = hashes;
      this.params = params;
    }
    
    // required for serialization
    PartialMerkleTree._newInstance();
    
    factory PartialMerkleTree.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params}) => 
            new BitcoinSerialization.deserialize(new PartialMerkleTree._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params);
    
    int get transactionCount {
      _needInstance();
      return _transactionCount;
    }
    
    Uint8List get matchedChildBits {
      _needInstance();
      return _matchedChildBits;
    }
    
    List<Sha256Hash> get hashes {
      _needInstance();
      return new UnmodifiableListView(_hashes);
    }

    @override
    Uint8List _serialize() {
      List<int> result = new List<int>()
        ..addAll(Utils.uintToBytesLE(_transactionCount, 4))
        ..addAll(new VarInt(_hashes.length).serialize());
      _hashes.forEach((hash) => result.addAll(hash.serialize()));
      result..addAll(new VarInt(_matchedChildBits.length).serialize())
        ..addAll(_matchedChildBits);
      return new Uint8List.fromList(result);
    }

    @override
    void _deserialize() {
      _transactionCount = _readUintLE();
      int nbHashes = _readVarInt();
      _hashes = new List<Sha256Hash>(nbHashes);
      for(int i = 0 ; i < nbHashes ; i++) {
        _hashes[i] = new Sha256Hash.deserialize(_readBytes(32));
      }
      _matchedChildBits = _readByteArray();
    }

    @override
    void _deserializeLazy() {
      _serializationCursor += 4;
      int nbHashes = _readVarInt();
      _serializationCursor += Sha256Hash.LENGTH * nbHashes;
      int nbBytes = _readVarInt();
      _serializationCursor += nbBytes;
    }
    
    /**
     * Extracts tx hashes that are in this merkle tree
     * and returns the merkle root of this tree.
     * 
     * The returned root should be checked against the
     * merkle root contained in the block header for security.
     * 
     * @param matchedHashes A list which will contain the matched txn (will be cleared)
     *                      Required to be a LinkedHashSet in order to retain order or transactions in the block
     * @return the merkle root of this merkle tree
     */
    Sha256Hash getTxnHashAndMerkleRoot(List<Sha256Hash> matchedHashes) {
      _needInstance();
      matchedHashes.clear();
      
      // An empty set will not work
      if (_transactionCount == 0)
        throw new VerificationException("Got a CPartialMerkleTree with 0 transactions");
      // check for excessively high numbers of transactions
      if (_transactionCount > Block.MAX_BLOCK_SIZE ~/ 60) // 60 is the lower bound for the size of a serialized CTransaction
        throw new VerificationException("Got a CPartialMerkleTree with more transactions than is possible");
      // there can never be more hashes provided than one for every txid
      if (_hashes.length > _transactionCount)
        throw new VerificationException("Got a CPartialMerkleTree with more hashes than transactions");
      // there must be at least one bit per node in the partial tree, and at least one node per hash
      if (_matchedChildBits.length * 8 < _hashes.length)
        throw new VerificationException("Got a CPartialMerkleTree with fewer matched bits than hashes");
      // calculate height of tree
      int height = 0;
      while (_getTreeWidth(height, _transactionCount) > 1)
        height++;
      // traverse the partial tree
      _ValuesUsedForPMT used = new _ValuesUsedForPMT();
      Sha256Hash merkleRoot = new Sha256Hash(_recursiveExtractHashes(height, 0, used, matchedHashes));
      // verify that all bits were consumed (except for the padding caused by serializing it as a byte sequence)
      if ((used.bitsUsed + 7) ~/ 8 != _matchedChildBits.length ||
          // verify that all hashes were consumed
          used.hashesUsed != _hashes.length)
        throw new VerificationException("Got a CPartialMerkleTree that didn't need all the data it provided");
      
      return merkleRoot;
    }
    
    // helper function to efficiently calculate the number of nodes at given height in the merkle tree
    static int _getTreeWidth(int height, int txCount) => (txCount + (1 << height) - 1) >> height;
    
    // recursive function that traverses tree nodes, consuming the bits and hashes produced by TraverseAndBuild.
    // it returns the hash of the respective node.
    Uint8List _recursiveExtractHashes(int height, int pos, _ValuesUsedForPMT used, List<Sha256Hash> matchedHashes) {
      _needInstance();
      if (used.bitsUsed >= _matchedChildBits.length * 8) {
        // overflowed the bits array - failure
        throw new VerificationException("CPartialMerkleTree overflowed its bits array");
      }
      bool parentOfMatch = Utils.checkBitLE(_matchedChildBits, used.bitsUsed++);
      if (height == 0 || !parentOfMatch) {
        // if at height 0, or nothing interesting below, use stored hash and do not descend
        if (used.hashesUsed >= _hashes.length) {
          // overflowed the hash array - failure
          throw new VerificationException("CPartialMerkleTree overflowed its hash array");
        }
        if (height == 0 && parentOfMatch) // in case of height 0, we have a matched txid
          matchedHashes.add(_hashes[used.hashesUsed]);
        return _hashes[used.hashesUsed++].bytes;
      } else {
        // otherwise, descend into the subtrees to extract matched txids and hashes
        Uint8List left = _recursiveExtractHashes(height - 1, pos * 2, used, matchedHashes), right;
        if (pos * 2 + 1 < _getTreeWidth(height - 1, _transactionCount))
          right = _recursiveExtractHashes(height - 1, pos * 2 + 1, used, matchedHashes);
        else
          right = left;
        // and combine them before returning
        return Utils.reverseBytes(Utils.doubleDigestTwoInputs(
            Utils.reverseBytes(left), Utils.reverseBytes(right)));
      }
    }
}

class _ValuesUsedForPMT {
  int bitsUsed, hashesUsed;
  _ValuesUsedForPMT([this.bitsUsed = 0, this.hashesUsed = 0]);
}
