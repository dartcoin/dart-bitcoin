part of dartcoin.core;

class _TestNetParams extends NetworkParameters {
  
  static Block _genesis;
  
  const _TestNetParams() : super._(
      addressHeader: 111, 
      magicValue: 0x0B110907,
      id: "org.bitcoin.test",
      port: 18333);
  
  Block get genesisBlock {
    if(_genesis == null) {
      Block genesis = NetworkParameters._createGenesis(this);
      genesis.timestamp = 1296688602;
      genesis.nonce = 414098458;
      genesis.bits = 0x1d00ffff;
      _genesis = genesis;
    }
    return _genesis;
  }
}