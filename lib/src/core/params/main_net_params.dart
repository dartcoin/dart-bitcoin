part of bitcoin.core;

class _MainNetParams extends NetworkParameters {
  static Block _genesis;

  const _MainNetParams()
      : super._(
            addressHeader: 0,
            p2shHeader: 5,
            magicValue: 0xF9BEB4D9, // 0xD9B4BEF9
            id: "org.bitcoin.production",
            port: 8333);

  Block get genesisBlock {
    if (_genesis == null) {
      Block genesis = NetworkParameters._createGenesis(this)
        ..timestamp = 1231006505
        ..nonce = 2083236893
        ..difficultyTarget = 0x1d00ffff;
      _genesis = genesis;
    }
    return _genesis;
  }

  BigInt get proofOfWorkLimit => BigInt.parse("00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16);
}
