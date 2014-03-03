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
  
  static const int HEADER_LENGTH = 4 + COMMAND_LENGTH + 4 + 4;
  static const int COMMAND_LENGTH = 12;
  
  int _magic;
  String command;
  
  int _payloadLength;
  Uint8List _checksum;
  
  Message(String this.command) {
    _magic = NetworkParameters.MAIN_NET.magicValue;
  }
  
  factory Message.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) {
    String command = _parseCommand(bytes.sublist(4));
    return _MESSAGE_DESERIALIZERS[command](bytes, length, lazy, params, protocolVersion); 
  }
  
  int get magic {
    _needInstance();
    return _magic;
  }
  
  /**
   * It is important to note that the checksum invalidates when objects embedded,
   * like blocks and transactions, change. 
   * Use [calculateChecksum()] to manually refresh the sum after a change.
   */
  Uint8List get checksum {
    if(_checksum == null)
      calculateChecksum();
    return new Uint8List.fromList(_checksum);
  }
  
  Uint8List calculateChecksum() {
    Sha256Hash sum = new Sha256Hash.doubleDigest(payload);
    _checksum = sum.bytes.getRange(0, 4);
  }
  
  Uint8List get payload => serialize().sublist(HEADER_LENGTH);
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    if(bytes.length < 16) 
      throw new SerializationException("Cannot deserialize because serialization is too short.");
    _magic = Utils.bytesToUintLE(bytes, 4);
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
    if(payloadLength != _deserializePayload(bytes.sublist(HEADER_LENGTH)))
      throw new SerializationException("Incorrect payload length");
    if(!_validChecksum(sum))
      throw new SerializationException("Incorrect checksum provided in serialized message");
    return HEADER_LENGTH + payloadLength;
  }
  
  int _deserializePayload(Uint8List bytes);
  
  bool _validChecksum(Uint8List sum) {
    calculateChecksum();
    return Utils.equalLists(sum, _checksum);
  }
  
  Uint8List _serialize() {
    if(command.length > 12)
      throw new SerializationException("Command length should not be greater than 12.");
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
  
  Uint8List _serialize_payload();
  
  static String _parseCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH;
    while(bytes[word - 1] == 0) word--;
    return new AsciiCodec().decode(bytes.sublist(0, word));
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int payloadLength = Utils.bytesToUintLE(bytes.sublist(4 + COMMAND_LENGTH), 4);
    return HEADER_LENGTH + payloadLength;
  }
  
  void _needInstance([bool clearCache]) {
    super._needInstance(clearCache);
    _checksum = null;
  }
  
  
}





