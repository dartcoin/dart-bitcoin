part of dartcoin.core;

typedef Message _MessageInstanceGenerator();

abstract class Message extends Object with BitcoinSerialization {

  static final Map<String, _MessageInstanceGenerator> _MESSAGE_INSTANCE_GENERATORS = {
      "addr"         : () => new AddressMessage._newInstance(),
      "alert"        : () => new AlertMessage._newInstance(),
      "block"        : () => new BlockMessage._newInstance(),
      "filteradd"    : () => new FilterAddMessage._newInstance(),
      "filterclear"  : () => new FilterClearMessage._newInstance(),
      "filterload"   : () => new FilterLoadMessage._newInstance(),
      "getaddr"      : () => new GetAddressMessage._newInstance(),
      "getblocks"    : () => new GetBlocksMessage._newInstance(),
      "getdata"      : () => new GetDataMessage._newInstance(),
      "getheaders"   : () => new GetHeadersMessage._newInstance(),
      "headers"      : () => new HeadersMessage._newInstance(),
      "inv"          : () => new InventoryMessage._newInstance(),
      "mempool"      : () => new MemPoolMessage._newInstance(),
      "merkleblock"  : () => new MerkleBlockMessage._newInstance(),
      "notfound"     : () => new NotFoundMessage._newInstance(),
      "ping"         : () => new PingMessage._newInstance(),
      "pong"         : () => new PongMessage._newInstance(),
      "tx"           : () => new TransactionMessage._newInstance(),
      "verack"       : () => new VerackMessage._newInstance(),
      "version"      : () => new VersionMessage._newInstance(),
  };
  
  static const int HEADER_LENGTH = 24; // = 4 + COMMAND_LENGTH + 4 + 4;
  static const int COMMAND_LENGTH = 12;
  
  String command;
  
  int _payloadLength;
  Uint8List _checksum;
  
  Message(String this.command, NetworkParameters params) {
    this.params = params;
  }
  
  factory Message.deserialize(Uint8List bytes, 
      {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) {
    if(bytes.length < HEADER_LENGTH)
      throw new SerializationException("Too few bytes to be a Message");
    String command = _parseCommand(bytes.sublist(4, 4 + COMMAND_LENGTH));
    if(!_MESSAGE_INSTANCE_GENERATORS.containsKey(command))
      throw new SerializationException("Unknown message command code: $command");
    BitcoinSerialization instance = _MESSAGE_INSTANCE_GENERATORS[command]();
    return new BitcoinSerialization._internal(instance, bytes.buffer, bytes.offsetInBytes, length,
        lazy, retain, params, protocolVersion, null);
  }
  
  /**
   * This is a very ineficient method for deserializing a message from its payload.
   * 
   * This method is mostly used for testing purposes.
   */
  factory Message.fromPayload(String command, Uint8List payloadBytes, 
      {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) {
    if(params == null) params = NetworkParameters.MAIN_NET;
    if(command.length > 12)
      throw new ArgumentError("Command length should not be greater than 12.");
    Uint8List checksum = _calculateChecksum(payloadBytes);
    Uint8List bytes = new Uint8List.fromList(new List<int>()
    // the magic value
    ..addAll(utils.uintToBytesLE(params.magicValue, 4))
    // the command code
    ..addAll(_encodeCommand(command))
    // the payload length
    ..addAll(utils.uintToBytesLE(payloadBytes.length, 4))
    // the checksum
    ..addAll(checksum)
    // the payload
    ..addAll(payloadBytes));
    BitcoinSerialization instance = _MESSAGE_INSTANCE_GENERATORS[command]();
    return new BitcoinSerialization._internal(instance, bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes,
        lazy, retain, params, protocolVersion, null);
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
      crypto.doubleDigest(payload).sublist(0, 4);
  
  Uint8List get payload => serialize().sublist(HEADER_LENGTH);
  
  @override
  void _deserialize() {
    _setParamsFromMagic(_readUintLE());
    String cmd = _parseCommand(_readBytes(COMMAND_LENGTH));
    if(command != null && command != cmd)
      throw new SerializationException("Deserialization error: serialization belongs to different message type.");
    int payloadLength = _readUintLE();
    Uint8List sum = _readBytes(4);
    _serializationLength = HEADER_LENGTH + payloadLength; // must be set here because _validSum requires payload, which requires this value
    int prePayloadCursor = _serializationCursor;
    _deserializePayload();
    if(_serializationCursor - prePayloadCursor != payloadLength)
      throw new SerializationException("Incorrect payload length");
    // hacky method to get the payload back:
    Uint8List payload = new Uint8List.view(_serializationBuffer, _serializationOffset + HEADER_LENGTH, payloadLength);
    if(!utils.equalLists(sum, _calculateChecksum(payload)))
      throw new SerializationException("Incorrect checksum provided in serialized message");
  }

  @override
  void _deserializeLazy() {
    // magic + command
    _serializationCursor += 4 + COMMAND_LENGTH;
    int payloadLength = _readUintLE();
    // checksum + payload
    _serializationCursor += 4 + payloadLength;
  }
  
  void _setParamsFromMagic(int magic) {
    if(params != null && params.magicValue == magic)
      return;
    params = NetworkParameters.PARAMS_BY_MAGIC[magic];
    if(params == null)
      throw new SerializationException("Unknown network packet magic used.");
  }
  
  void _deserializePayload();

  @override
  void _serialize(ByteSink sink) {
    if(command.length > 12)
      throw new SerializationException("Command length should not be greater than 12.");
    // the magic value
    _writeUintLE(sink, params.magicValue);
    // the command code
    sink.add(_encodeCommand(command));
    // prepare payload
    ByteSink payloadSink = new ByteSink();
    _serializePayload(payloadSink);
    // the payload length
    _writeUintLE(sink, payloadSink.size);
    // the checksum
    _checksum = _calculateChecksum(payloadSink.toUint8List());
    sink.add(_checksum);
    // the payload
    sink.add(payloadSink.toUint8List());
  }
  
  void _serializePayload(ByteSink sink);
  
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
  
  void _needInstance([bool clearCache = false]) {
    super._needInstance(clearCache);
    if(clearCache)
      _checksum = null;
  }
  
  
}





