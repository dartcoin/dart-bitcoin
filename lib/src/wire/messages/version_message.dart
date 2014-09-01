part of dartcoin.core;

class VersionMessage extends Message {
  
  static final BigInteger SERVICE_NODE_NETWORK = BigInteger.ONE;
  
  int clientVersion;
  BigInteger services;
  int time;
  PeerAddress myAddress;
  PeerAddress theirAddress;
  int nonce;
  String subVer;
  int lastHeight;
  bool relayBeforeFilter;

  /** The version of this library release, as a string. */
  static final String DARTCOIN_VERSION = "0.0.0-alpha";
  /** The value that is prepended to the subVer field of this application. */
  static final String LIBRARY_SUBVER = "/Dartcoin:" + DARTCOIN_VERSION + "/";
  
  /**
   * Create a new VersionMessage.
   * 
   * Most parameters can be left blank, the most important ones are
   * [lastHeight] and [relayBeforeFilter], all others most probably have the default value.
   */
  VersionMessage({ int this.lastHeight: 0,
                   bool this.relayBeforeFilter: false,
                   int this.clientVersion: NetworkParameters.PROTOCOL_VERSION,
                   BigInteger this.services,
                   int this.time: 0,
                   PeerAddress myAddress,
                   PeerAddress theirAddress,
                   int this.nonce,
                   String this.subVer,
                   NetworkParameters params: NetworkParameters.MAIN_NET }) : super("version", params) {
    if(services == null) services = BigInteger.ZERO;
    if(nonce == null) nonce = new Random().nextInt(0xffffffff);
    if(subVer == null) subVer = LIBRARY_SUBVER;
    // make sure a PeerAddress instance with protocolVersion = 0 is used
    if(myAddress != null) this.myAddress = myAddress._forVersionMessage;
    else this.myAddress = new PeerAddress.localhost(params: params, services: services, protocolVersion: 0);
    if(theirAddress != null) this.theirAddress = theirAddress._forVersionMessage; 
    else this.theirAddress = new PeerAddress.localhost(params: params, services: services, protocolVersion: 0);
    
    this.params = params;
    // we don't need to set PeerAddress's parent to this because no lazy serialization is supported
  }
  
  // required for serialization
  VersionMessage._newInstance() : super("version", null) { _lazySerialization = false; }
  
  /**
   * 
   * 
   * No lazy deserialization is supported for this kind of message. 
   */
  factory VersionMessage.deserialize(Uint8List bytes, {int length, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VersionMessage._newInstance(), bytes, length: length, lazy: false, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Uint8List get checksum => Message._calculateChecksum(payload);
  
  /**
   * Appends the given user-agent information to the subVer field. The subVer is composed of a series of
   * name:version pairs separated by slashes in the form of a path. For example a typical subVer field for BitCoinJ
   * users might look like "/BitCoinJ:0.4-SNAPSHOT/MultiBit:1.2/" where libraries come further to the left.<p>
   *
   * There can be as many components as you feel a need for, and the version string can be anything, but it is
   * recommended to use A.B.C where A = major, B = minor and C = revision for software releases, and dates for
   * auto-generated source repository snapshots. A valid subVer begins and ends with a slash, therefore name
   * and version are not allowed to contain such characters. <p>
   *
   * Anything put in the "comments" field will appear in brackets and may be used for platform info, or anything
   * else. For example, calling <tt>appendToSubVer("MultiBit", "1.0", "Windows")</tt> will result in a subVer being
   * set of "/BitCoinJ:1.0/MultiBit:1.0(Windows)/. Therefore the / ( and ) characters are reserved in all these
   * components. If you don't want to add a comment (recommended), pass null.<p>
   *
   * See <a href="https://en.bitcoin.it/wiki/BIP_0014">BIP 14</a> for more information.
   *
   * @param comments Optional (can be null) platform or other node specific information.
   * @throws IllegalArgumentException if name, version or comments contains invalid characters.
   */
  void appendToSubVer(String name, String version, [String comments]) {
    if(!isValidSubVerComponent(name) || !isValidSubVerComponent(version) || (comments != null && !isValidSubVerComponent(comments)))
      throw new Exception("Invalid format");
    if (comments != null)
      subVer += "$name:$version($comments)/";
    else
      subVer += "$name:$version/";
  }

  static bool isValidSubVerComponent(String component) =>
    !(component.contains("/") || component.contains("(") || component.contains(")"));

  /**
   * Returns true if the clientVersion field is >= Pong.MIN_PROTOCOL_VERSION. If it is then ping() is usable.
   */
  bool get isPingPongSupported => clientVersion >= PongMessage.MIN_PROTOCOL_VERSION;

  /**
   * Returns true if the clientVersion field is >= FilteredBlock.MIN_PROTOCOL_VERSION. If it is then Bloom filtering
   * is available and the memory pool of the remote peer will be queried when the downloadData property is true.
   */
  bool get isBloomFilteringSupported => clientVersion >= FilteredBlock.MIN_PROTOCOL_VERSION;

  /**
   * Returns true if the version message indicates the sender has a full copy of the block chain,
   * or if it's running in client mode (only has the headers).
   */
  bool get hasBlockChain => (services & SERVICE_NODE_NETWORK) == SERVICE_NODE_NETWORK;
  
  @override
  bool operator ==(VersionMessage other) {
    return other is VersionMessage &&
        other.lastHeight == lastHeight &&
        other.clientVersion == clientVersion &&
        other.services == services &&
        other.time == time &&
        other.subVer == subVer &&
        other.myAddress == myAddress &&
        other.theirAddress == theirAddress &&
        other.relayBeforeFilter == relayBeforeFilter;
  }
  
  @override
  int get hashCode {
    return lastHeight ^ clientVersion ^ services.hashCode ^ time ^ subVer.hashCode ^ myAddress.hashCode
        ^ theirAddress.hashCode * (relayBeforeFilter ? 1 : 2);
  }

  @override
  int _deserializePayload() {
    clientVersion = _readUintLE();
    services = Utils.bytesToUBigIntLE(_readBytes(8));//_readUintLE(8);
    time = _readUintLE(8);
    // for PeerAddresses in the version message, the protocolVersion must be hard coded to 0
    myAddress = _readObject(new PeerAddress._newInstance().._protocolVersion = 0);
    if(clientVersion < 106) return;
    // only when protocolVersion >= 106
    theirAddress = _readObject(new PeerAddress._newInstance().._protocolVersion = 0);
    nonce = _readUintLE(8);
    // initialize default values for flags that may be missing from old nodes
    subVer = "";
    lastHeight = 0;
    relayBeforeFilter = true;
    if(_deserializationBytesAvailable() <= 0) return;
    subVer = _readVarStr();
    if(_deserializationBytesAvailable() <= 0) return;
    lastHeight = _readUintLE();
    if(_deserializationBytesAvailable() <= 0) return;
    relayBeforeFilter = _readUintLE(1) != 0;
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeUintLE(sink, clientVersion);
    sink.add(Utils.uBigIntToBytesLE(services, 8));
    _writeUintLE(sink, time, 8);
    _writeObject(sink, myAddress);
    // we are version >= 106
    _writeObject(sink, theirAddress);
    _writeUintLE(sink, nonce, 8);
    _writeString(sink, subVer);
    _writeUintLE(sink, lastHeight);
    sink.add(relayBeforeFilter ? 1 : 0);
  }
}






