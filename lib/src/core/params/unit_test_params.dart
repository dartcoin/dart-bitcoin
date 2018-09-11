part of bitcoin.core;

class _UnitTestParams extends NetworkParameters {
  static Block _genesis;

  const _UnitTestParams()
      : super._(
            addressHeader: 111,
            p2shHeader: 196,
            magicValue: 0x0B110907,
            // copied from bitcoinj to indicate that we use the same params as bitcoinj
            id: "com.google.bitcoin.unittest",
            port: 18333);

  Block get genesisBlock {
    if (_genesis == null) {
      Block genesis = NetworkParameters._createGenesis(this)
        ..timestamp = new DateTime.now().millisecondsSinceEpoch ~/ 1000
        ..difficultyTarget = Block.EASIEST_DIFFICULTY_TARGET
        ..solve(this);
      _genesis = genesis;
    }
    return _genesis;
  }

  BigInt get proofOfWorkLimit =>
      BigInt.parse("00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16);
}
