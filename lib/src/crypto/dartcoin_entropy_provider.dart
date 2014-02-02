part of dartcoin;

class DartcoinEntropyProvider {
  
  static DartcoinEntropyProvider _instance;
  
  Set _sources;
  
  static DartcoinEntropyProvider get instance {
    if(_instance == null) {
      DartcoinEntropyProvider newInstance = new DartcoinEntropyProvider();
      newInstance._sources = new HashSet();
      newInstance._sources.add(new AutoSeedBlockCtrRandom());
    }
  }
  
}