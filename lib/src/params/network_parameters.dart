part of dartcoin.core;

abstract class NetworkParameters {
  
  //TODO this are only the ones already used
  //      should add more on the go and add remaining (not yet used) ones at the end
  
  // USE THESE AS PARAMS
  
  static final NetworkParameters MAIN_NET = new _MainNetParams();
  
  
  // GLOBAL PARAMETERS
  
  static final int PROTOCOL_VERSION = 70001;
  static final Uint8List SATOSHI_KEY = Utils.hexToBytes("04fc9702847840aaf195de8442ebecedf5b095cdbb9bc716bda9110971b28a49e0ead8564ff0db22209e0374782c093bb899692d524e9d6a6956e7c5ecbcd68284");
  
  
  // NETWORK-SPECIFIC PARAMETERS
  
  int addressHeader;
  int magicValue;
  
}