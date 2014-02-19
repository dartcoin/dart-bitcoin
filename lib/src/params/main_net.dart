part of dartcoin.core;

class _MainNetParams extends NetworkParameters {
  
  const _MainNetParams() : super._(
      addressHeader: 0, 
      magicValue: 0xD9B4BEF9,
      id: "org.bitcoin.production",
      port: 8333);
}