part of dartcoin.core;

typedef Message _MessageDeserializer(Uint8List bytes, int length, bool lazy, NetworkParameters params, int protocolVersion);

abstract class Message extends Object with BitcoinSerialization {
  
  // closurizing constructors is not (yet) possible
  static final Map<String, _MessageDeserializer> _MESSAGE_DESERIALIZERS = {
        "addr"         : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new AddressMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "alert"        : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new AlertMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "block"        : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new BlockMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "filteradd"    : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new FilterAddMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "filterclear"  : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new FilterClearMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "filterload"   : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new FilterLoadMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "getaddr"      : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new GetAddressMessage.deserialize(bts, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "getblocks"    : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new GetBlocksMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "getdata"      : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new GetDataMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "getheaders"   : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new GetHeadersMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "headers"      : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new HeadersMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "inv"          : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new InventoryMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "mempool"      : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new MemPoolMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "merkleblock"  : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new MerkleBlockMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "notfound"     : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new NotFoundMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "ping"         : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new PingMessage.deserialize(bts, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "pong"         : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new PongMessage.deserialize(bts, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "tx"           : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new TransactionMessage.deserialize(bts, length: len, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "verack"       : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new VerackMessage.deserialize(bts, lazy: laz, retain: ret, params: par, protocolVersion: prv),
        "version"      : (Uint8List bts, int len, bool laz, bool ret, NetworkParameters par, int prv) => new VersionMessage.deserialize(bts, length: len, retain: ret, params: par, protocolVersion: prv),
  };
  
  static const int HEADER_LENGTH = 4 + COMMAND_LENGTH + 4 + 4;
  static const int COMMAND_LENGTH = 12;
  
  String command;
  
  int _payloadLength;
  Uint8List _checksum;
  
  Message(String this.command, NetworkParameters params) {
    this.params = params;
  }
  
  factory Message.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) {
    if(bytes.length < HEADER_LENGTH)
      throw new SerializationException("Too few bytes to be a Message");
    String command = _parseCommand(bytes.sublist(4, 4 + COMMAND_LENGTH));
    if(!_MESSAGE_DESERIALIZERS.containsKey(command))
      throw new SerializationException("Unknown message command code: $command");
    return _MESSAGE_DESERIALIZERS[command](bytes, length, lazy, retain, params, protocolVersion); 
  }
  
  factory Message.fromPayload(String command, Uint8List payloadBytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) {
    if(params == null) params = NetworkParameters.MAIN_NET;
    if(command.length > 12)
      throw new ArgumentError("Command length should not be greater than 12.");
    List<int> result = new List<int>();
    // the magic value
    result.addAll(Utils.uintToBytesLE(params.magicValue, 4));
    // the command code
    result.addAll(_encodeCommand(command));
    // the payload length
    result.addAll(Utils.uintToBytesLE(payloadBytes.length, 4));
    // the checksum
    Uint8List checksum = _calculateChecksum(payloadBytes);
    result.addAll(checksum);
    // the payload
    result.addAll(payloadBytes);
    return new Message.deserialize(new Uint8List.fromList(result), length: result.length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  }
  
  /**
   * It is important to note that the checksum invalidates when objects embedded,
   * like blocks and transactions, change. 
   * Use [calculateChecksum()] to manually refresh the sum after a change.
   */
  Uint8List get checksum {
    if(_checksum == null)
      _checksum = _calculateChecksum(payload);
    return new Uint8List.fromList(_checksum);
  }
  
  static Uint8List _calculateChecksum(Uint8List payload) => 
      Utils.doubleDigest(payload).sublist(0, 4);
  
  Uint8List get payload => serialize().sublist(HEADER_LENGTH);
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    if(bytes.length < 16) 
      throw new SerializationException("Cannot deserialize because serialization is too short.");
    _setParamsFromMagic(Utils.bytesToUintLE(bytes, 4));
    offset += 4;
    String cmd = _parseCommand(bytes.sublist(offset, offset + COMMAND_LENGTH));
    offset += COMMAND_LENGTH;
    if(command != null && command != cmd)
      throw new SerializationException("Deserialization error: serialization belongs to different message type.");
    int payloadLength = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    _serializationLength = HEADER_LENGTH + payloadLength; // must be set here because _validSum requires payload, which requires this value
    offset += 4;
    Uint8List sum = bytes.sublist(offset, offset + 4);
    offset += 4;
    Uint8List payload = bytes.sublist(HEADER_LENGTH);
    if(payloadLength != _deserializePayload(payload, lazy, retain))
      throw new SerializationException("Incorrect payload length");
    if(!Utils.equalLists(sum, _calculateChecksum(payload)))
      throw new SerializationException("Incorrect checksum provided in serialized message");
    return HEADER_LENGTH + payloadLength;
  }
  
  void _setParamsFromMagic(int magic) {
    if(params != null && params.magicValue == magic)
      return;
    params = NetworkParameters.PARAMS_BY_MAGIC[magic];
    if(params == null)
      throw new SerializationException("Unknown network packet magic used.");
  }
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain);
  
  Uint8List _serialize() {
    if(command.length > 12)
      throw new SerializationException("Command length should not be greater than 12.");
    List<int> result = new List<int>();
    // the magic value
    result.addAll(Utils.uintToBytesLE(params.magicValue, 4));
    // the command code
    result.addAll(_encodeCommand(command));
    // prepare payload
    Uint8List payloadBytes = _serialize_payload();
    // the payload length
    result.addAll(Utils.uintToBytesLE(payloadBytes.length, 4));
    // the checksum
    _checksum = _calculateChecksum(payloadBytes);
    result.addAll(_checksum);
    // the payload
    result.addAll(payloadBytes);
    return new Uint8List.fromList(result);
  }
  
  Uint8List _serialize_payload();
  
  static String _parseCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH;
    while(bytes[word - 1] == 0) word--;
    return new AsciiDecoder().convert(bytes.sublist(0, word));
  }
  
  static List<int> _encodeCommand(String command) {
    List<int> commandBytes = new List.from(new AsciiCodec().encode(command));
    while(commandBytes.length < COMMAND_LENGTH)
      commandBytes.add(0);
    return commandBytes;
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int payloadLength = Utils.bytesToUintLE(bytes.sublist(4 + COMMAND_LENGTH), 4);
    return HEADER_LENGTH + payloadLength;
  }
  
  void _needInstance([bool clearCache = false]) {
    super._needInstance(clearCache);
    if(clearCache)
      _checksum = null;
  }
  
  
}





