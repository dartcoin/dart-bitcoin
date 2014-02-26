part of dartcoin.core;

typedef Message _MessageDeserializer(Uint8List bytes, int length, bool lazy, NetworkParameters params, int protocolVersion);

abstract class Message extends Object with BitcoinSerialization {
  
  // closurizing constructors is not (yet) possible
  static final Map<String, _MessageDeserializer> _MESSAGE_DESERIALIZERS = {
        "addr"         : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new AddrMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "alert"        : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new AlertMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "block"        : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new BlockMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "filteradd"    : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new FilterAddMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "filterclear"  : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new FilterClearMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "filterload"   : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new FilterLoadMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "getaddr"      : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new GetAddrMessage.deserialize(bts, lazy: laz, params: par, protocolVersion: prv),
        "getblocks"    : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new GetBlocksMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "getdata"      : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new GetDataMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "getheaders"   : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new GetHeadersMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "headers"      : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new HeadersMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "inv"          : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new InvMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "mempool"      : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new MemPoolMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "merkleblock"  : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new MerkleBlockMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "notfound"     : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new NotFoundMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "ping"         : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new PingMessage.deserialize(bts, lazy: laz, params: par, protocolVersion: prv),
        "pong"         : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new PongMessage.deserialize(bts, lazy: laz, params: par, protocolVersion: prv),
        "tx"           : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new TxMessage.deserialize(bts, length: len, lazy: laz, params: par, protocolVersion: prv),
        "verack"       : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new VerackMessage.deserialize(bts, lazy: laz, params: par, protocolVersion: prv),
        "version"      : (Uint8List bts, int len, bool laz, NetworkParameters par, int prv) => new VersionMessage.deserialize(bts, length: len, params: par, protocolVersion: prv),
  };
  
  Map<String, Function> _messageConstructors = {
    "block": BlockMessage
  };
  
  static const int HEADER_LENGTH = 4 + COMMAND_LENGTH;
  static const int COMMAND_LENGTH = 12;
  
  int _magic;
  String command;
  
  Uint8List _payload;
  Uint8List _checksum;
  
  Message(String this.command) {
    _magic = NetworkParameters.MAIN_NET.magicValue;
  }
  
  Message.withPayload(String this.command, Uint8List payload) {
    _magic = NetworkParameters.MAIN_NET.magicValue;
    _payload = payload;
  }
  
  Message.withMagic(int magic, String this.command, [Uint8List payload]) {
    _magic = magic;
    _payload = payload;
  }
  
  factory Message.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) {
    String command = _parseCommand(bytes.sublist(4));
    return _MESSAGE_DESERIALIZERS[command](bytes, length, lazy, params, protocolVersion); 
  }
  
  /**
   * This method is used by Message subclasses when deserializing themselves.
   * Because they only need the payload to deserialize, this method does the following:
   * - parses the magic and command value fro [bytes] and returns the offset at which the payload begins 
   * - sets the magic value of [message]
   * - verifies the command string from the serialization with [message.command]
   *    (TODO it might be a possibility to make it possible to skip this check when it has already been performed)
   */
  static int _preparePayloadSerialization(Uint8List bytes, Message message) {
    if(bytes.length < 16) 
      throw new Exception("Cannot deserialize because serialization is too short.");
    message._magic = Utils.bytesToUintLE(bytes, 4);
    String cmd = _parseCommand(bytes.sublist(4, HEADER_LENGTH));
    if(cmd != message.command)
      throw new Exception("Deserialization error: serialization belongs to different message type.");
    return HEADER_LENGTH;
  }
  
  /**
   * This is used to deserialize a message object from it's payload. 
   * The magic value is added afterwards. 
   */
  //Message._fromPayload(Uint8List payloadBytes);
  
  Uint8List _serialize_payload();
  
  int get magic {
    _needInstance();
    return _magic;
  }
  
  Uint8List get payload {
    if(_payload == null)
      return _serialize_payload();
    return _payload;
  }
  
  Uint8List get checksum {
    if(_checksum == null)
      _checksum = _calculateChecksum();
    return _checksum;
  }
  
  Uint8List _calculateChecksum() {
    Sha256Hash sum = Sha256Hash.doubleDigest(payload);
    _checksum = sum.bytes.getRange(0, 4);
  }
  
  Uint8List _serialize() {
    if(command.length > 12)
      throw new Exception("Command length should not be greater than 12.");
    List<int> result = new List<int>();
    // the magic value
    result.addAll(Utils.uintToBytesLE(magic, 4));
    // the command code
    List<int> commandBytes = new AsciiCodec().encode(command);
    while(commandBytes.length < 12) {
      commandBytes.add(0);
    }
    result.addAll(commandBytes);
    // the payload length
    result.addAll(Utils.uintToBytesLE(payload.length, 4));
    // the checksum
    result.addAll(checksum);
    // the payload
    if(payload != null)
      result.addAll(payload);
    else
      result.addAll(_serialize_payload());
    return new Uint8List.fromList(result);
  }
  
  static String _parseCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH - 1;
    while(bytes[word] == 0) word--;
    return new AsciiCodec().decode(bytes.sublist(0, word));
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int payloadLength = Utils.bytesToUintLE(bytes.sublist(4 + COMMAND_LENGTH), 4);
    return 4 + COMMAND_LENGTH + 4 + 4 + payloadLength;
  }
  
  
}





