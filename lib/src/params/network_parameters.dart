part of dartcoin.core;

abstract class NetworkParameters {
  
  // USE THESE AS PARAMS

  static const NetworkParameters MAIN_NET  = const _MainNetParams();
  static const NetworkParameters TEST_NET  = const _TestNetParams();
  
  static const NetworkParameters UNIT_TEST = const _UnitTestParams();
  
  static final Map<int,NetworkParameters> PARAMS_BY_MAGIC = {
      MAIN_NET.magicValue  : MAIN_NET,
      TEST_NET.magicValue  : TEST_NET,
      UNIT_TEST.magicValue : UNIT_TEST,
  };
  
  
  static const List<NetworkParameters> SUPPORTED_PARAMS = const [MAIN_NET, TEST_NET];
  
  
  // GLOBAL PARAMETERS
  
  static const int PROTOCOL_VERSION = 70001;
  static final Uint8List SATOSHI_KEY = Utils.hexToBytes("04fc9702847840aaf195de8442ebecedf5b095cdbb9bc716bda9110971b28a49e0ead8564ff0db22209e0374782c093bb899692d524e9d6a6956e7c5ecbcd68284");
  
  
  // NETWORK-SPECIFIC PARAMETERS
  
  final int addressHeader;
  final int p2shHeader;
  final int magicValue;
  final String id;
  
  final int port;
  
  const NetworkParameters._({
    int this.addressHeader,
    int this.p2shHeader,
    int this.magicValue, 
    String this.id,
    int this.port
  });
  
  Block get genesisBlock;
  BigInteger get proofOfWorkLimit;
  
  List<int> get acceptableAddressHeaders => [addressHeader, p2shHeader];

  /**
   * The maximum money to be generated
   */
  int get MAX_MONEY => 21000000 * Units.COIN;


  static Block _createGenesis(NetworkParameters params) {
    Block genesisBlock = new Block(params: params);
    Transaction t = new Transaction(params: params);
    // A script containing the difficulty bits and the following message:
    //
    //   "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
    Uint8List bytes = Utils.hexToBytes
        ("04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73");
    t.addInput(new TransactionInput(scriptSig: new Script(bytes), params: params));
    Script pubKeyScript = new ScriptBuilder(true)
      .data(Utils.hexToBytes("04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f"))
      .op(ScriptOpCodes.OP_CHECKSIG)
      .build();
    t.addOutput(new TransactionOutput(value: Units.toSatoshi(50), scriptPubKey: pubKeyScript, params: params));
    genesisBlock.addTransaction(t, false);
    return genesisBlock;
  }
  
}