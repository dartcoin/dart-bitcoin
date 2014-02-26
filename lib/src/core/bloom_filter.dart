part of dartcoin.core;


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
class BloomFilter extends Object with BitcoinSerialization {
    
    Uint8List _data;
    int _hashFuncs;
    int _nTweak;
    int _nFlags;

    // Same value as the reference client
  // A filter of 20,000 items and a false positive rate of 0.1% or one of 10,000 items and 0.0001% is just under 36,000 bytes
  static const int MAX_FILTER_SIZE = 36000;
  // There is little reason to ever have more hash functions than 50 given a limit of 36,000 bytes
  static const int MAX_HASH_FUNCS = 50;

  /**
   * Construct a BloomFilter by deserializing payloadBytes
   */
  factory BloomFilter.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params}) => 
          new BitcoinSerialization.deserialize(new BloomFilter(0, 0.0, 0, null), bytes, length: length, lazy: lazy, params: params);
  
  
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
  BloomFilter(int elements, double falsePositiveRate, int randomNonce, BloomUpdate updateFlag) {
      // The following formulas were stolen from Wikipedia's page on Bloom Filters (with the addition of min(..., MAX_...))
      //                        Size required for a given number of elements and false-positive rate
      int size = min((-1  / (pow(log(2), 2)) * elements * log(falsePositiveRate)).floor(),
                          (MAX_FILTER_SIZE * 8) / 8).floor();
      _data = new Uint8List(size <= 0 ? 1 : size);
      // Optimal number of hash functions for a given filter size and element count.
      _hashFuncs = min(_data.length * 8 / elements * log(2), MAX_HASH_FUNCS);
      _nTweak = randomNonce;
      _nFlags = (0xff & updateFlag.val);
  }
  
  Uint8List get data {
    _needInstance();
    return _data;
  }
  
  int get hashFuncs {
    _needInstance();
    return _hashFuncs;
  }
  
  int get nTweak {
    _needInstance();
    return _nTweak;
  }
  
  int get nFlags {
    _needInstance();
    return _nFlags;
  }
  
  /**
   * Returns the theoretical false positive rate of this filter if were to contain the given number of elements.
   */
  double getFalsePositiveRate(int elements) {
    _needInstance();
    return pow(1 - pow(E, -1.0 * (_hashFuncs * elements) / (_data.length * 8)), _hashFuncs);
  }

  @override
  String toString() => "Bloom Filter of size ${data.length} with $hashFuncs hash functions.";

  @override
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    VarInt size = new VarInt.deserialize(bytes, lazy: false);
    offset += size.size;
    _data = bytes.sublist(offset, offset + size.value);
    offset += size.value;
    if (_data.length > MAX_FILTER_SIZE)
      throw new SerializationException("Bloom filter out of size range.");
    _hashFuncs = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    offset += 4;
    if (_hashFuncs > MAX_HASH_FUNCS)
      throw new SerializationException("Bloom filter hash function count out of range");
    _nTweak = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    offset += 4;
    _nFlags = bytes[offset];
    offset += 1;
    return offset;
  }
  
  /**
   * Serializes this message to the provided stream. If you just want the raw bytes use bitcoinSerialize().
   */
  Uint8List _serialize() {
    List<int> result = new List<int>()
      ..addAll(new VarInt(_data.length).serialize())
      ..addAll(_data)
      ..addAll(Utils.uintToBytesLE(_hashFuncs, 4))
      ..addAll(Utils.uintToBytesLE(_nTweak, 4))
      ..add(_nFlags);
    return new Uint8List.fromList(result);
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) {
    VarInt dataSize = new VarInt.deserialize(bytes, lazy: false);
    return dataSize.size + dataSize.value + 4 + 4 + 1;
  }

  static int _ROTL32 (int x, int r) {
    return (x << r) | Utils.lsr(x, 32 - r);
  }
  
  int _hash(int hashNum, Uint8List object) {
    _needInstance();
    // The following is MurmurHash3 (x86_32), see http://code.google.com/p/smhasher/source/browse/trunk/MurmurHash3.cpp
    int h1 = hashNum * 0xFBA4C795 + _nTweak;
    final int c1 = 0xcc9e2d51;
    final int c2 = 0x1b873593;

    int numBlocks = (object.length ~/ 4) * 4;
    // body
    for(int i = 0; i < numBlocks; i += 4) {
      int k1 = (object[i] & 0xFF) |
            ((object[i+1] & 0xFF) << 8) |
            ((object[i+2] & 0xFF) << 16) |
            ((object[i+3] & 0xFF) << 24);
      
      k1 *= c1;
      k1 = _ROTL32(k1,15);
      k1 *= c2;

      h1 ^= k1;
      h1 = _ROTL32(h1,13); 
      h1 = h1*5+0xe6546b64;
    }
    
    int k1 = 0;
    if((object.length & 3) >= 3)
      k1 ^= (object[numBlocks + 2] & 0xff) << 16;
    if((object.length & 3) >= 2)
      k1 ^= (object[numBlocks + 1] & 0xff) << 8;
    if((object.length & 3) >= 1) {
      k1 ^= (object[numBlocks] & 0xff);
      k1 *= c1; k1 = _ROTL32(k1,15); k1 *= c2; h1 ^= k1;
    }

    // finalization
    h1 ^= object.length;
    h1 ^= Utils.lsr(h1, 16);
    h1 *= 0x85ebca6b;
    h1 ^= Utils.lsr(h1, 13);
    h1 *= 0xc2b2ae35;
    h1 ^= Utils.lsr(h1, 16);
    
    return ((h1&0xFFFFFFFF) % (_data.length * 8));
  }
  
  /**
   * Returns true if the given object matches the filter
   * (either because it was inserted, or because we have a false-positive)
   */
  bool contains(Uint8List object) {
    _needInstance();
    for (int i = 0; i < _hashFuncs; i++) {
      if (!Utils.checkBitLE(_data, _hash(i, object)))
        return false;
    }
    return true;
  }
  
  /**
   * Insert the given arbitrary data into the filter
   */
  void insert(Uint8List object) {
    _needInstance(true);
    for (int i = 0; i < _hashFuncs; i++)
      Utils.setBitLE(_data, _hash(i, object));
  }

  /**
   * Sets this filter to match all objects. A Bloom filter which matches everything may seem pointless, however,
   * it is useful in order to reduce steady state bandwidth usage when you want full blocks. Instead of receiving
   * all transaction data twice, you will receive the vast majority of all transactions just once, at broadcast time.
   * Solved blocks will then be send just as Merkle trees of tx hashes, meaning a constant 32 bytes of data for each
   * transaction instead of 100-300 bytes as per usual.
   */
  void setMatchAll() {
    _needInstance(true);
    _data = new Uint8List.fromList([0xff]);
  }

  /**
   * Copies filter into this. Filter must have the same size, hash function count and nTweak or an
   * IllegalArgumentException will be thrown.
   */
  void merge(BloomFilter filter) {
    _needInstance(true);
    filter._needInstance();
    if (!this.matchesAll() && !filter.matchesAll()) {
      if(!(filter._data.length == _data.length &&
          filter._hashFuncs == _hashFuncs &&
          filter._nTweak == _nTweak))
        throw new Exception("Invalid filter passed as parameter; read the docs.");
      for (int i = 0; i < _data.length; i++)
        _data[i] |= filter._data[i];
    } else {
      _data = new Uint8List.fromList([0xff]);
    }
  }

  /**
   * Returns true if this filter will match anything. See {@link com.google.bitcoin.core.BloomFilter#setMatchAll()}
   * for when this can be a useful thing to do.
   */
  bool matchesAll() {
    _needInstance();
    for (int b in _data)
      if (b != 0xff)
          return false;
    return true;
  }
  
  @override
  bool equals(Object other) {
    return other is BloomFilter &&
           other.hashFuncs == this.hashFuncs &&
           other.nTweak == this.nTweak &&
           Utils.equalLists(other.data, this.data);
  }

  @override
  int get hashCode {
    //TODO
      //return Objects.hashCode(hashFuncs, nTweak, Arrays.hashCode(data));
  }
}

/** The BLOOM_UPDATE_* constants control when the bloom filter is auto-updated by the peer using
it as a filter, either never, for all outputs or only for pay-2-pubkey outputs (default) */
class BloomUpdate {
  static const BloomUpdate UPDATE_NONE = const BloomUpdate._(0);
  static const BloomUpdate UPDATE_ALL = const BloomUpdate._(1);
  /** Only adds outpoints to the filter if the output is a pay-to-pubkey/pay-to-multisig script */
  static const BloomUpdate UPDATE_P2PUBKEY_ONLY = const BloomUpdate._(2);
  
  final int val;
  const BloomUpdate._(int this.val);
}
