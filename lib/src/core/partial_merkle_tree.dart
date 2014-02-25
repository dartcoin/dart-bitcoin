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
    
    factory PartialMerkleTree.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) => 
            new BitcoinSerialization.deserialize(new PartialMerkleTree(), bytes, length: length, lazy: lazy, params: params);
    
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
    
    Uint8List _serialize() {
      List<int> result = new List<int>()
        ..addAll(Utils.uintToBytesLE(_transactionCount, 4))
        ..addAll(new VarInt(_hashes.length).serialize());
      _hashes.forEach((hash) => result.addAll(hash.bytes.reversed));
      result..addAll(new VarInt(_matchedChildBits.length).serialize())
        ..addAll(_matchedChildBits);
      return new Uint8List.fromList(result);
    }
    
    int _deserialize(Uint8List bytes) {
      int offset = 0;
      _transactionCount = Utils.bytesToUintLE(bytes, 4);
      offset += 4;
      VarInt nHashes = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
      offset += nHashes.size;
      _hashes = new List<Sha256Hash>();
      for(int i = 0 ; i < nHashes.value ; i++) {
        _hashes.add(new Sha256Hash(bytes.sublist(offset, offset + Sha256Hash.LENGTH)));
        offset += Sha256Hash.LENGTH;
      }
      VarInt nFlagBytes = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
      offset += nFlagBytes.size;
      _matchedChildBits = bytes.sublist(offset, offset + nFlagBytes.value);
      offset += nFlagBytes.value;
      return offset;
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
     * @throws ProtocolException if this partial merkle tree is invalid
     */
    Sha256Hash getTxnHashAndMerkleRoot(List<Sha256Hash> matchedHashes) {
      _needInstance();
      matchedHashes.clear();
      
      // An empty set will not work
      if (_transactionCount == 0)
        throw new Exception("Got a CPartialMerkleTree with 0 transactions");
      // check for excessively high numbers of transactions
      if (_transactionCount > Block.MAX_BLOCK_SIZE ~/ 60) // 60 is the lower bound for the size of a serialized CTransaction
        throw new Exception("Got a CPartialMerkleTree with more transactions than is possible");
      // there can never be more hashes provided than one for every txid
      if (_hashes.length > _transactionCount)
        throw new Exception("Got a CPartialMerkleTree with more hashes than transactions");
      // there must be at least one bit per node in the partial tree, and at least one node per hash
      if (_matchedChildBits.length * 8 < _hashes.length)
        throw new Exception("Got a CPartialMerkleTree with fewer matched bits than hashes");
      // calculate height of tree
      int height = 0;
      while (_getTreeWidth(height) > 1)
        height++;
      // traverse the partial tree
      _ValuesUsed used = new _ValuesUsed();
      Sha256Hash merkleRoot = _recursiveExtractHashes(height, 0, used, matchedHashes);
      // verify that all bits were consumed (except for the padding caused by serializing it as a byte sequence)
      if ((used.bitsUsed+7)/8 != _matchedChildBits.length ||
          // verify that all hashes were consumed
          used.hashesUsed != _hashes.length)
        throw new Exception("Got a CPartialMerkleTree that didn't need all the data it provided");
      
      return merkleRoot;
    }
    
    // helper function to efficiently calculate the number of nodes at given height in the merkle tree
    int _getTreeWidth(int height) => (transactionCount+(1 << height)-1) >> height;
    
    // recursive function that traverses tree nodes, consuming the bits and hashes produced by TraverseAndBuild.
    // it returns the hash of the respective node.
    Sha256Hash _recursiveExtractHashes(int height, int pos, _ValuesUsed used, List<Sha256Hash> matchedHashes) {
      _needInstance();
      if (used.bitsUsed >= _matchedChildBits.length * 8) {
        // overflowed the bits array - failure
        throw new Exception("CPartialMerkleTree overflowed its bits array");
      }
      bool parentOfMatch = Utils.checkBitLE(_matchedChildBits, used.bitsUsed++);
      if (height == 0 || !parentOfMatch) {
        // if at height 0, or nothing interesting below, use stored hash and do not descend
        if (used.hashesUsed >= _hashes.length) {
          // overflowed the hash array - failure
          throw new Exception("CPartialMerkleTree overflowed its hash array");
        }
        if (height == 0 && parentOfMatch) // in case of height 0, we have a matched txid
          matchedHashes.add(_hashes[used.hashesUsed]);
        return _hashes[used.hashesUsed++];
      } else {
        // otherwise, descend into the subtrees to extract matched txids and hashes
        Uint8List left = _recursiveExtractHashes(height-1, pos*2, used, matchedHashes).bytes, right;
        if (pos * 2 + 1 < _getTreeWidth(height-1))
          right = _recursiveExtractHashes(height-1, pos*2+1, used, matchedHashes).bytes;
        else
          right = left;
        // and combine them before returning
        return new Sha256Hash(
            Utils.doubleDigestTwoInputs(left.reversed, right.reversed).reversed);
      }
    }
}

class _ValuesUsed {
  int bitsUsed = 0, hashesUsed = 0;
  _ValuesUsed([this.bitsUsed, this.hashesUsed]);
}
