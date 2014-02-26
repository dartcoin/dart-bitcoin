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
  int startHeight;
  bool relay;

  /** The version of this library release, as a string. */
  static final String DARTCOIN_VERSION = "0.0.0-alpha";
  /** The value that is prepended to the subVer field of this application. */
  static final String LIBRARY_SUBVER = "/Dartcoin:" + DARTCOIN_VERSION + "/";
  
  VersionMessage({ int this.clientVersion: NetworkParameters.PROTOCOL_VERSION,
                   BigInteger this.services,
                   int this.time: 0,
                   PeerAddress this.myAddress,
                   PeerAddress this.theirAddress,
                   int this.nonce: 0,
                   String this.subVer,
                   int this.startHeight: 0,
                   bool this.relay: false,
                   NetworkParameters params: NetworkParameters.MAIN_NET }) : super("version") {
    if(services == null) services = BigInteger.ZERO;
    this.params = params;
  } 
  
  factory VersionMessage.deserialize(Uint8List bytes, {int length, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VersionMessage(), bytes, length: length, lazy: false, params: params, protocolVersion: protocolVersion);

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

  static bool isValidSubVerComponent(String component) {
    return !(component.contains("/") || component.contains("(") || component.contains(")"));
  }

  /**
   * Returns true if the clientVersion field is >= Pong.MIN_PROTOCOL_VERSION. If it is then ping() is usable.
   */
  bool get isPingPongSupported {
    return clientVersion >= PongMessage.MIN_PROTOCOL_VERSION;
  }

  /**
   * Returns true if the clientVersion field is >= FilteredBlock.MIN_PROTOCOL_VERSION. If it is then Bloom filtering
   * is available and the memory pool of the remote peer will be queried when the downloadData property is true.
   */
  bool get isBloomFilteringSupported {
    return clientVersion >= FilteredBlock.MIN_PROTOCOL_VERSION;
  }

  /**
   * Returns true if the version message indicates the sender has a full copy of the block chain,
   * or if it's running in client mode (only has the headers).
   */
  bool get hasBlockChain {
    return (services & SERVICE_NODE_NETWORK) == SERVICE_NODE_NETWORK;
  }
  
  @override
  bool operator ==(VersionMessage other) {
    return other is VersionMessage &&
        other.startHeight == startHeight &&
        other.clientVersion == clientVersion &&
        other.services == services &&
        other.time == time &&
        other.subVer == subVer &&
        other.myAddress == myAddress &&
        other.theirAddress == theirAddress &&
        other.relay == relay;
  }
  
  @override
  int get hashCode {
    return startHeight ^ clientVersion ^ services.hashCode ^ time ^ subVer.hashCode ^ myAddress.hashCode
        ^ theirAddress.hashCode * (relay ? 1 : 2);
  }
  
  
  Uint8List _serialize_payload() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesLE(clientVersion, 4))
      ..addAll(Utils.uBigIntToBytesLE(services, 8))
      ..addAll(Utils.uintToBytesLE(time, 8))
      ..addAll(myAddress.serialize())
      // we are version >= 106
      ..addAll(theirAddress.serialize())
      ..addAll(Utils.uintToBytesLE(nonce, 8))
      ..addAll(new VarStr(subVer).serialize())
      ..addAll(Utils.uintToBytesLE(startHeight, 4))
      ..add(relay ? 1 : 0));
  }
  
  int _deserializePayload(Uint8List bytes) {
    int offset = 0;
    clientVersion = Utils.bytesToUintLE(bytes, 4);
    offset += 4;
    services = Utils.bytesToUBigIntLE(bytes.sublist(offset), 8);
    offset += 8;
    time = Utils.bytesToUintLE(bytes.sublist(offset), 8);
    offset += 8;
    myAddress = new PeerAddress.deserialize(bytes.sublist(offset), lazy: false, protocolVersion: clientVersion, params: this.params);
    offset += myAddress.serializationLength;
    if(clientVersion < 106) return offset;
    // only when protocolVersion >= 106
    theirAddress = new PeerAddress.deserialize(bytes.sublist(offset), lazy: false, protocolVersion: clientVersion, params: this.params);
    offset += theirAddress.serializationLength;
    nonce = Utils.bytesToUintLE(bytes.sublist(offset), 8);
    offset += 8;
    VarStr sv = new VarStr.deserialize(bytes.sublist(offset), lazy: false, params: this.params);
    offset += sv.serializationLength;
    subVer = sv.content;
    startHeight = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    offset += 4;
    relay = bytes[offset] != 0;
    offset += 1;
    return offset;
  }
}






