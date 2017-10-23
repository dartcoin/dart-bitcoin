library dartcoin.rpc.bitcoind;

import "package:json_rpc_2/json_rpc_2.dart" as json_rpc;

import "package:dartcoin/core.dart";
import "package:dartcoin/json.dart";

import "bitcoin_core_api.dart";

abstract class BitcoinAPI {
  json_rpc.Client _proxy;

  BitcoinAPI(var rpcProxy) {
    _proxy = rpcProxy;
  }

  BitcoinAPI.withURI(Uri uri) {
    var stream;
    if (uri.scheme == "ws") {
//      stream =
    }
  }

  //void addMultiSigAddress(int nRequired, ...) //TODO when public keys ready

  //void addNode() //TODO when peernodes are ready

  void backupWallet(String destination) {
    _proxy.backupwallet(destination);
  }

  //Transaction createMultiSig(int nRequired, ..) //TODO when public keys ready

  Uint8List createRawTransaction(List<TransactionOutPoint> inputs, Map<Address, int> outputs) {
    List<Map<String, Object>> inputMaps = new List<Map<String, Object>>();
    inputs.forEach((input) => inputMaps.add({"txid": input.txid.toString(), "vout": input.index}));

    Map<String, int> outputMap = new HashMap<String, int>();
    outputs.forEach((address, value) => outputMap.putIfAbsent(address.toString(), value));

    return utils.hexToBytes(_proxy.createrawtransaction(inputMaps, outputMap));
  }

  //Transaction decodeRawTransaction(Uint8List raw) //TODO when JSON decoding is ready

  KeyPair dumpPrivKey(Address address) {
    //TODO when ECKey is ready
  }

  void encryptWallet(String passphrase) {
    _proxy.encryptwallet(passphrase);
  }

  String getAccount(Address address) {
    //TODO is String return type correct?
    return _proxy.getaccount(address.toString());
  }

  Address getAccountAddress(String account) {
    return new Address(_proxy.getaccountaddress(account));
  }

  //String getAddedNodeInfo(bool dns, Peer node) //TODO when peer representation is ready

  List<Address> getAddressesByAccount(String account) {
    List<Address> addresses = new List<Address>();
    _proxy.getaddressesbyaccount(account).forEach((addr) => addresses.add(new Address(addr)));
    return addresses;
  }

  /**
   * Balance in Bitcoin.
   * Use Units.toSatoshi() to get balance in satoshi
   */
  num getBalance([String account = "", int minconf = 1]) {
    return _proxy.getbalance(account, minconf);
  }

  // not (yet) officially released
  /*Sha256Hash getBestBlockHash() {
    return new Sha256Hash(utils.hexToBytes(_proxy.getbestblockhash()));
  }*/

  Block getBlock(Sha256Hash hash) {
    //TODO decode json
  }

  int getBlockCount() {
    return _proxy.getblockcount();
  }

  Sha256Hash getBlockHash(int height) {
    return new Sha256Hash(utils.hexToBytes(_proxy.getblockhash(height)));
  }

  //getblocktemplate //TODO investigate

  int getConnectionCount() {
    return _proxy.getconnectioncount();
  }

  int getDifficulty() {
    return _proxy.getdifficulty();
  }

  bool getGenerate() {
    return _proxy.getgenerate();
  }

  int getHashPerSec() {
    return _proxy.gethashespersec();
  }

  Map<String, String> getInfo() {
    return _proxy.getinfo();
  }

  Map<String, String> getMiningInfo() {
    return _proxy.getmininginfo();
  }

  Address getNewAddress([String account = ""]) {
    return new Address(_proxy.getnewaddress(account));
  }

  //getpeerinfo //TODO output format?

  // not (yet) officially released
  //Address getRawChangeAddress([String account = ""])

  List<Sha256Hash> getRawMempool() {
    List<Sha256Hash> hashes = new List<Sha256Hash>();
    _proxy.getrawmempool().forEach((h) => hashes.add(new Sha256Hash(utils.hexToBytes(h))));
    return hashes;
  }

  Uint8List getRawTransaction(Sha256Hash txid, [bool verbose = false]) {
    int verb = verbose ? 1 : 0;
    return utils.hexToBytes(_proxy.getrawtransaction(txid.toString(), verb));
  }

  num getReceivedByAccount([String account = "", int minconf = 1]) {
    return _proxy.getreceivedbyaccount(account, minconf);
  }

  num getReceivedByAddress(Address address, [int minconf = 1]) {
    return _proxy.getreceivedbyaddress(address.toString(), minconf);
  }

  Transaction getTransaction(Sha256Hash txid) {
    //TODO decode JSON
  }

//TODO continue

}
