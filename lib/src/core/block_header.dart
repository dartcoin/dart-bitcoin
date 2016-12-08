part of dartcoin.core;


class BlockHeader extends BitcoinSerializable {

  int version;
  Hash256 previousBlock;
  Hash256 merkleRoot;
  int timestamp;
  int difficultyTarget;
  int nonce;

  Hash256 _hash;

  BlockHeader({ Hash256 hash,
                int this.version: Block.BLOCK_VERSION,
                Hash256 this.previousBlock,
                Hash256 this.merkleRoot,
                int this.timestamp,
                int this.difficultyTarget,
                int this.nonce: 0}) {
    this._hash = hash;
    previousBlock = previousBlock ?? Hash256.ZERO_HASH;
    difficultyTarget = difficultyTarget ?? Block.EASIEST_DIFFICULTY_TARGET;
  }

  factory BlockHeader.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new BlockHeader.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }

  /// Create an empty instance.
  BlockHeader.empty();

  /// Used only as superconstructor in Block
  BlockHeader._header(hash, version, previousBlock, merkleRoot, timestamp,
      difficultyTarget, nonce) : this(
    hash: hash,
    version: version,
    previousBlock: previousBlock,
    merkleRoot: merkleRoot,
    timestamp: timestamp,
    difficultyTarget: difficultyTarget,
    nonce: nonce
  );


  Hash256 get hash {
    if (_hash == null) {
      _hash = calculateHash();
    }
    return _hash;
  }

  DateTime get time => new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  void set time(DateTime time) {
    timestamp = time.millisecondsSinceEpoch ~/ 1000;
  }

  BigInteger get difficultyTargetAsInteger => utils.decodeCompactBits(difficultyTarget);

  /**
   * Returns the work represented by this block.
   *
   * Work is defined as the number of tries needed to solve a block in the
   * average case. Consider a difficulty target that covers 5% of all possible
   * hash values. Then the work of the block will be 20. As the target gets
   * lower, the amount of work goes up.
   */
  BigInteger get work =>
      Block._LARGEST_HASH / (difficultyTargetAsInteger + BigInteger.ONE);

  Hash256 calculateHash() {
    var buffer = new bytes.Buffer();
    _serializeHeaderOnly(buffer);
    Uint8List checksum = crypto.doubleDigest(buffer.asBytes());
    return new Hash256(utils.reverseBytes(checksum));
  }

  @override
  bool operator ==(BlockHeader other) {
    if(other.runtimeType != BlockHeader) return false;
    if(identical(this, other)) return true;
    return hash == other.hash;
  }

  @override
  int get hashCode => (BlockHeader).hashCode ^ hash.hashCode;

  void bitcoinSerialize(bytes.Buffer buffer, int pver) =>
      _serializeHeaderOnly(buffer);

  void _serializeHeaderOnly(bytes.Buffer buffer) {
    writeUintLE(buffer, version);
    writeSHA256(buffer, previousBlock);
    writeSHA256(buffer, merkleRoot);
    writeUintLE(buffer, timestamp);
    writeUintLE(buffer, difficultyTarget);
    writeUintLE(buffer, nonce);
  }

  void bitcoinSerializeAsEmptyBlock(bytes.Buffer buffer, int pver) {
    _serializeHeaderOnly(buffer);
    buffer.addByte(0);
  }


  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    version = readUintLE(reader);
    previousBlock = readSHA256(reader);
    merkleRoot = readSHA256(reader);
    timestamp = readUintLE(reader);
    difficultyTarget = readUintLE(reader);
    nonce = readUintLE(reader);
  }


}