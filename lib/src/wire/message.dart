part of bitcoin.wire;

typedef Message _MessageGenerator();

abstract class Message extends BitcoinSerializable {
  static const String CMD_ADDR = "addr";
  static const String CMD_ALERT = "alert";
  static const String CMD_BLOCK = "block";
  static const String CMD_FILTERADD = "filteradd";
  static const String CMD_FILTERCLEAR = "filterclear";
  static const String CMD_FILTERLOAD = "filterload";
  static const String CMD_GETADDR = "getaddr";
  static const String CMD_GETBLOCKS = "getblocks";
  static const String CMD_GETDATA = "getdata";
  static const String CMD_GETHEADERS = "getheaders";
  static const String CMD_HEADERS = "headers";
  static const String CMD_INV = "inv";
  static const String CMD_MEMPOOL = "mempool";
  static const String CMD_MERKLEBLOCK = "merkleblock";
  static const String CMD_NOTFOUND = "notfound";
  static const String CMD_PING = "ping";
  static const String CMD_PONG = "pong";
  static const String CMD_TX = "tx";
  static const String CMD_VERACK = "verack";
  static const String CMD_VERSION = "version";

  static final Map<String, _MessageGenerator> _MESSAGE_GENERATORS = {
    CMD_ADDR: () => new AddressMessage.empty(),
    CMD_ALERT: () => new AlertMessage.empty(),
    CMD_BLOCK: () => new BlockMessage.empty(),
    CMD_FILTERADD: () => new FilterAddMessage.empty(),
    CMD_FILTERCLEAR: () => new FilterClearMessage.empty(),
    CMD_FILTERLOAD: () => new FilterLoadMessage.empty(),
    CMD_GETADDR: () => new GetAddressMessage.empty(),
    CMD_GETBLOCKS: () => new GetBlocksMessage.empty(),
    CMD_GETDATA: () => new GetDataMessage.empty(),
    CMD_GETHEADERS: () => new GetHeadersMessage.empty(),
    CMD_HEADERS: () => new HeadersMessage.empty(),
    CMD_INV: () => new InventoryMessage.empty(),
    CMD_MEMPOOL: () => new MemPoolMessage.empty(),
    CMD_MERKLEBLOCK: () => new MerkleBlockMessage.empty(),
    CMD_NOTFOUND: () => new NotFoundMessage.empty(),
    CMD_PING: () => new PingMessage.empty(),
    CMD_PONG: () => new PongMessage.empty(),
    CMD_TX: () => new TransactionMessage.empty(),
    CMD_VERACK: () => new VerackMessage.empty(),
    CMD_VERSION: () => new VersionMessage.empty(),
  };

  static const int HEADER_LENGTH = 24; // = 4 + COMMAND_LENGTH + 4 + 4;
  static const int COMMAND_LENGTH = 12;

  String get command;

  Message();

  factory Message.forCommand(String command) {
    if (!_MESSAGE_GENERATORS.containsKey(command)) {
      throw new ArgumentError("$command is not a valid message command");
    }
    return _MESSAGE_GENERATORS[command]();
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver);
  void bitcoinSerialize(bytes.Buffer buffer, int pver);

  /// Decode a serialized message.
  static Message decode(Uint8List msgBytes, int magicValue, int pver) {
    if (msgBytes.length < HEADER_LENGTH)
      throw new SerializationException("Too few bytes to be a Message");

    // create a Reader for deserializing
    var reader = new bytes.Reader(msgBytes);

    // verify the magic value
    int magic = readUintLE(reader);
    if (magic != magicValue) {
      throw new SerializationException("Invalid magic value: $magic. Expected $magicValue.");
    }

    // read the command, length and checksum
    String cmd = _readCommand(readBytes(reader, COMMAND_LENGTH));
    int payloadLength = readUintLE(reader);
    Uint8List checksum = readBytes(reader, 4);

    // create a checksum reader to be able to determine the checksum afterwards
    ChecksumReader payloadReader = new ChecksumReader(reader, new crypto.DoubleSHA256Digest());
    int preLength = reader.remainingLength;

    // generate an empty concrete message instance and make it parse
    Message msg = new Message.forCommand(cmd);
    msg.bitcoinDeserialize(payloadReader, pver);
    int postLength = reader.remainingLength;

    // check if the payload was of the claimed size
    if (preLength - postLength != payloadLength) {
      throw new SerializationException("Incorrect payload length in message header "
          "(actual: ${(preLength - postLength)}, expected: $payloadLength");
    }

    // check the checksum
    Uint8List actualChecksum = payloadReader.checksum().sublist(0, 4);
    if (!utils.equalLists(checksum, actualChecksum)) {
      throw new SerializationException("Incorrect checksum provided in serialized message "
          "(actual: ${CryptoUtils.bytesToHex(actualChecksum)}, "
          "expected: ${CryptoUtils.bytesToHex(checksum)})");
    }

    return msg;
  }

  /// Encode a message to serialized format.
  static Uint8List encode(Message msg, int magicValue, int pver) {
    var buffer = new bytes.Buffer();

    // write magic value and command
    writeUintLE(buffer, magicValue);
    buffer.add(_encodeCommand(msg.command));

    // serialize the payload
    ChecksumBuffer payloadBuffer = new ChecksumBuffer(new crypto.DoubleSHA256Digest());
    msg.bitcoinSerialize(payloadBuffer, pver);

    // write payload size and checksum
    writeUintLE(buffer, payloadBuffer.length);
    buffer.add(payloadBuffer.checksum().sublist(0, 4));

    // write the actual payload
    writeBytes(buffer, payloadBuffer.asBytes());

    return buffer.asBytes();
  }

  static String _readCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH;
    while (bytes[word - 1] == 0) word--;
    return ASCII.decode(bytes.sublist(0, word));
  }

  static List<int> _encodeCommand(String command) {
    List<int> commandBytes = new List.from(ASCII.encode(command));
    while (commandBytes.length < COMMAND_LENGTH) commandBytes.add(0);
    return commandBytes;
  }
}
