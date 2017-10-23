part of dartcoin.wire;

class PingMessage extends Message {
  @override
  String get command => Message.CMD_PING;

  int nonce;

  PingMessage([
    int this.nonce = null,
  ]) {
    if (nonce != null && nonce < 0) throw new Exception("Nonce value should be at least zero");
  }

  factory PingMessage.generate() {
    int nonce = new Random().nextInt(1 << 8);
    return new PingMessage(nonce);
  }

  /// Create an empty instance.
  PingMessage.empty();

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
