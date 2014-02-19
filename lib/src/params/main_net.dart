part of dartcoin.core;

class _MainNetParams extends NetworkParameters {
  
  static Block _genesis;
  
  const _MainNetParams() : super._(
      addressHeader: 0, 
      magicValue: 0xD9B4BEF9,
      id: "org.bitcoin.production",
      port: 8333);
  
  Block get genesisBlock {
    if(_genesis == null)
      _genesis = NetworkParameters._createGenesis(this); 
    return _genesis;
  }
}