part of bitcoin.wire;

class HeadersMessage extends Message {
  @override
  String get command => Message.CMD_HEADERS;

  List<BlockHeader> headers;

  HeadersMessage(List<BlockHeader> this.headers);

  /// Create an empty instance.
  HeadersMessage.empty();

  void addHeader(BlockHeader header) {
    headers.add(header);
  }

  void removeHeader(BlockHeader header) {
    headers.remove(header);
  }

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbHeaders = readVarInt(reader).toInt();
    List<BlockHeader> newHeaders = new List<BlockHeader>(nbHeaders);
    for (int i = 0; i < nbHeaders; i++) {
      newHeaders[i] = readObject(reader, new BlockHeader.empty(), pver);
      reader.readByte(); // 00 byte
    }
    headers = newHeaders;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, new BigInt.from(headers.length));
    for (BlockHeader header in headers) {
      header.bitcoinSerializeAsEmptyBlock(buffer, pver);
    }
  }
}
