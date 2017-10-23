part of bitcoin.wire;

class PongMessage extends Message {
  @override
  String get command => Message.CMD_PONG;

  /** The smallest protocol version that supports the pong response (BIP 31). Anything beyond version 60000. */
  static const int MIN_PROTOCOL_VERSION = 60001;

  int nonce;

  PongMessage([
    int this.nonce = null,
  ]) {
    if (nonce != null && nonce < 0) throw new Exception("Nonce value should be at least zero");
  }

  PongMessage.fromPing(PingMessage ping) {
    nonce = ping.nonce;
  }

  /// Create an empty instance.
  PongMessage.empty();

  bool get hasNonce => nonce != null;

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    nonce = readUintLE(reader, 8);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    if (hasNonce)
      writeUintLE(buffer, nonce, 8);
    else
      writeUintLE(buffer, 0, 8);
  }
}
