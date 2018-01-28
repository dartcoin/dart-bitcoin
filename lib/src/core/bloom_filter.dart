part of bitcoin.core;

/**
 * <p>A Bloom filter is a probabilistic data structure which can be sent to another client so that it can avoid
 * sending us transactions that aren't relevant to our set of keys. This allows for significantly more efficient
 * use of available network bandwidth and CPU time.</p>
 * 
 * <p>Because a Bloom filter is probabilistic, it has a configurable false positive rate. So the filter will sometimes
 * match transactions that weren't inserted into it, but it will never fail to match transactions that were. This is
 * a useful privacy feature - if you have spare bandwidth the false positive rate can be increased so the remote peer
 * gets a noisy picture of what transactions are relevant to your wallet.</p>
 */
class BloomFilter extends BitcoinSerializable {
  Uint8List data;
  int hashFuncs;
  int nTweak;
  int nFlags;

  // Same value as the reference client
  // A filter of 20,000 items and a false positive rate of 0.1% or one of 10,000 items and 0.0001% is just under 36,000 bytes
  static const int MAX_FILTER_SIZE = 36000;
  // There is little reason to ever have more hash functions than 50 given a limit of 36,000 bytes
  static const int MAX_HASH_FUNCS = 50;

  /**
   * <p>Constructs a new Bloom Filter which will provide approximately the given false positive
   * rate when the given number of elements have been inserted.</p>
   * 
   * <p>If the filter would otherwise be larger than the maximum allowed size, it will be
   * automatically downsized to the maximum size.</p>
   * 
   * <p>To check the theoretical false positive rate of a given filter, use {@link BloomFilter#getFalsePositiveRate(int)}</p>
   * 
   * <p>The anonymity of which coins are yours to any peer which you send a BloomFilter to is
   * controlled by the false positive rate.</p>
   * 
   * <p>For reference, as of block 187,000, the total number of addresses used in the chain was roughly 4.5 million.</p>
   * 
   * <p>Thus, if you use a false positive rate of 0.001 (0.1%), there will be, on average, 4,500 distinct public
   * keys/addresses which will be thought to be yours by nodes which have your bloom filter, but which are not
   * actually yours.</p>
   * 
   * <p>Keep in mind that a remote node can do a pretty good job estimating the order of magnitude of the false positive
   * rate of a given filter you provide it when considering the anonymity of a given filter.</p>
   * 
   * <p>In order for filtered block download to function efficiently, the number of matched transactions in any given
   * block should be less than (with some headroom) the maximum size of the MemoryPool used by the Peer
   * doing the downloading (default is {@link MemoryPool#MAX_SIZE}). See the comment in processBlock(FilteredBlock)
   * for more information on this restriction.</p>
   * 
   * <p>randomNonce is a tweak for the hash function used to prevent some theoretical DoS attacks.
   * It should be a random value, however secureness of the random value is of no great consequence.</p>
   * 
   * <p>updateFlag is used to control filter behavior</p>
   */
  BloomFilter(int elements, double falsePositiveRate, int randomNonce,
      [BloomUpdate updateFlag = BloomUpdate.UPDATE_P2PUBKEY_ONLY]) {
    if (elements == null || falsePositiveRate == null || randomNonce == null)
      throw new ArgumentError("The required arguments should not be null");
    // The following formulas were stolen from Wikipedia's page on Bloom Filters (with the addition of min(..., MAX_...))
    //                        Size required for a given number of elements and false-positive rate
    int size = min((-1 / (pow(log(2), 2)) * elements * log(falsePositiveRate)).floor(),
            MAX_FILTER_SIZE * 8) ~/
        8;
    data = new Uint8List(size <= 0 ? 1 : size);
    // Optimal number of hash functions for a given filter size and element count.
    hashFuncs = min((data.length * 8 / elements * log(2)).floor(), MAX_HASH_FUNCS);
    nTweak = randomNonce;
    nFlags = (0xff & updateFlag.index);
  }

  /// Create an empty instance.
  BloomFilter.empty();

  /**
   * Returns the theoretical false positive rate of this filter if were to contain the given number of elements.
   */
  double getFalsePositiveRate(int elements) {
    return pow(1 - pow(E, -1.0 * (hashFuncs * elements) / (data.length * 8)), hashFuncs);
  }

  @override
  String toString() => "Bloom Filter of size ${data.length} with $hashFuncs hash functions.";

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    data = readByteArray(reader);
    if (data.length > MAX_FILTER_SIZE)
      throw new SerializationException("Bloom filter out of size range.");
    hashFuncs = readUintLE(reader);
    if (hashFuncs > MAX_HASH_FUNCS)
      throw new SerializationException("Bloom filter hash function count out of range");
    nTweak = readUintLE(reader);
    nFlags = readUintLE(reader, 1);
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeByteArray(buffer, data);
    writeUintLE(buffer, hashFuncs);
    writeUintLE(buffer, nTweak);
    writeBytes(buffer, [nFlags]);
  }

  static int _rotateLeft32(int x, int r) {
    return (x << r) | utils.lsr(x, 32 - r);
  }

  int _hash(int hashNum, Uint8List object) {
    // The following is MurmurHash3 (x86_32), see http://code.google.com/p/smhasher/source/browse/trunk/MurmurHash3.cpp
    // implementation copied from BitcoinJ
    //TODO implement in Pointy Castle?
    int h1 = hashNum * 0xFBA4C795 + nTweak;
    final int c1 = 0xcc9e2d51;
    final int c2 = 0x1b873593;

    int numBlocks = (object.length ~/ 4) * 4;
    // body
    for (int i = 0; i < numBlocks; i += 4) {
      int k1 = (object[i] & 0xFF) |
          ((object[i + 1] & 0xFF) << 8) |
          ((object[i + 2] & 0xFF) << 16) |
          ((object[i + 3] & 0xFF) << 24);

      k1 *= c1;
      k1 = _rotateLeft32(k1, 15);
      k1 *= c2;

      h1 ^= k1;
      h1 = _rotateLeft32(h1, 13);
      h1 = h1 * 5 + 0xe6546b64;
    }

    int k1 = 0;
    if ((object.length & 3) >= 3) k1 ^= (object[numBlocks + 2] & 0xff) << 16;
    if ((object.length & 3) >= 2) k1 ^= (object[numBlocks + 1] & 0xff) << 8;
    if ((object.length & 3) >= 1) {
      k1 ^= (object[numBlocks] & 0xff);
      k1 *= c1;
      k1 = _rotateLeft32(k1, 15);
      k1 *= c2;
      h1 ^= k1;
    }

    // finalization
    h1 ^= object.length;
    h1 ^= utils.lsr(h1, 16);
    h1 *= 0x85ebca6b;
    h1 ^= utils.lsr(h1, 13);
    h1 *= 0xc2b2ae35;
    h1 ^= utils.lsr(h1, 16);

    return ((h1 & 0xFFFFFFFF) % (data.length * 8));
  }

  /**
   * Returns true if the given object matches the filter
   * (either because it was inserted, or because we have a false-positive)
   */
  bool contains(Uint8List object) {
    for (int i = 0; i < hashFuncs; i++) {
      if (!utils.checkBitLE(data, _hash(i, object))) return false;
    }
    return true;
  }

  /**
   * Insert the given arbitrary data into the filter
   */
  void insert(Uint8List object) {
    for (int i = 0; i < hashFuncs; i++) {
      utils.setBitLE(data, _hash(i, object));
    }
  }

  /**
   * Sets this filter to match all objects. A Bloom filter which matches everything may seem pointless, however,
   * it is useful in order to reduce steady state bandwidth usage when you want full blocks. Instead of receiving
   * all transaction data twice, you will receive the vast majority of all transactions just once, at broadcast time.
   * Solved blocks will then be send just as Merkle trees of tx hashes, meaning a constant 32 bytes of data for each
   * transaction instead of 100-300 bytes as per usual.
   */
  void setMatchAll() {
    data = new Uint8List.fromList([0xff]);
  }

  /**
   * Copies filter into this. Filter must have the same size, hash function count and nTweak or an
   * IllegalArgumentException will be thrown.
   */
  void merge(BloomFilter filter) {
    if (!this.matchesAll() && !filter.matchesAll()) {
      if (!(filter.data.length == data.length &&
          filter.hashFuncs == hashFuncs &&
          filter.nTweak == nTweak)) {
        throw new Exception("Invalid filter passed as parameter; read the docs.");
      }
      for (int i = 0; i < data.length; i++) data[i] |= filter.data[i];
    } else {
      data = new Uint8List.fromList([0xff]);
    }
  }

  /**
   * Returns true if this filter will match anything. See {@link com.google.bitcoin.core.BloomFilter#setMatchAll()}
   * for when this can be a useful thing to do.
   */
  bool matchesAll() {
    for (int b in data) {
      if (b != 0xff) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != BloomFilter) return false;
    if (identical(this, other)) return true;
    return other.hashFuncs == this.hashFuncs &&
        other.nTweak == this.nTweak &&
        utils.equalLists(other.data, this.data);
  }

  @override
  int get hashCode {
    return hashFuncs ^ nTweak ^ utils.listHashCode(data);
  }
}

/** The BLOOM_UPDATE_* constants control when the bloom filter is auto-updated by the peer using
it as a filter, either never, for all outputs or only for pay-2-pubkey outputs (default) */
class BloomUpdate {
  static const BloomUpdate UPDATE_NONE = const BloomUpdate._(0);
  static const BloomUpdate UPDATE_ALL = const BloomUpdate._(1);
  /** Only adds outpoints to the filter if the output is a pay-to-pubkey/pay-to-multisig script */
  static const BloomUpdate UPDATE_P2PUBKEY_ONLY = const BloomUpdate._(2);

  final int index;
  const BloomUpdate._(int this.index);
}
