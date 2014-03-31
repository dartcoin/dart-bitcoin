part of dartcoin.core;

class TransactionSignature extends ECDSASignature with BitcoinSerialization {
  
  int _sigHashFlags;
  
  /**
   * Create a new TransactionSignature from an ECDSASignature.
   * 
   * It is possible to either set the sigHashFlags byte itself or 
   * specify a SigHash value and the anyoneCanPay bool.
   * When nothing is specified, the default SigHash.ALL and !anyoneCanPay settings are used.
   */
  TransactionSignature(ECDSASignature signature, {SigHash mode, bool anyoneCanPay, int sigHashFlags}) : super(signature.r, signature.s) {
    if(sigHashFlags != null) {
      if(mode != null || anyoneCanPay != null)
        throw new ArgumentError("Please specify either the sigHashFlags byte or mode + anyoneCanPay, not both.");
      _sigHashFlags = sigHashFlags;
    }
    else
      _setSigHashFlags(mode == null ? mode : SigHash.ALL, 
          anyoneCanPay == null ? anyoneCanPay : false);
  }

  // no lazy deserialization
  factory TransactionSignature.deserialize(Uint8List bytes, {int length, bool requireCanonical: false, NetworkParameters params}) {
    if(requireCanonical && !isEncodingCanonical(bytes)) throw new SerializationException("Signature is not canonical");
    if(length == null)
      length = bytes[1] + 2;
    TransactionSignature ts = new TransactionSignature(new ECDSASignature.fromDER(bytes.getRange(0, length - 1)), 
        sigHashFlags: bytes[length - 1]);
    ts.params = params;
    ts._serializationLength = length;
    return ts;
  }
  
  factory TransactionSignature.dummy() {
    ECDSASignature sig = new ECDSASignature(KeyPair.HALF_CURVE_ORDER, KeyPair.HALF_CURVE_ORDER);
    return new TransactionSignature(sig);
  }
  
  int get sigHashFlags => _sigHashFlags;
  
  void _setSigHashFlags(SigHash mode, bool anyoneCanPay) {
    _sigHashFlags = SigHash.sigHashFlagsValue(mode, anyoneCanPay);
  }

  /**
   * Returns true if the given signature is has canonical encoding, and will thus be accepted as standard by
   * the reference client. DER and the SIGHASH encoding allow for quite some flexibility in how the same structures
   * are encoded, and this can open up novel attacks in which a man in the middle takes a transaction and then
   * changes its signature such that the transaction hash is different but it's still valid. This can confuse wallets
   * and generally violates people's mental model of how Bitcoin should work, thus, non-canonical signatures are now
   * not relayed by default.
   */
  // copied from bitcoinj
  static bool isEncodingCanonical(Uint8List signature) {
    // See reference client's IsCanonicalSignature, https://bitcointalk.org/index.php?topic=8392.msg127623#msg127623
    // A canonical signature exists of: <30> <total len> <02> <len R> <R> <02> <len S> <S> <hashtype>
    // Where R and S are not negative (their first byte has its highest bit not set), and not
    // excessively padded (do not start with a 0 byte, unless an otherwise negative number follows,
    // in which case a single 0 byte is necessary and even required).
    if (signature.length < 9 || signature.length > 73)
      return false;

    int hashType = signature[signature.length-1] & ((~SigHash.ANYONE_CAN_PAY));
    if (hashType < (SigHash.ALL.value + 1) || hashType > (SigHash.SINGLE.value + 1))
      return false;

    //                   "wrong type"                  "wrong length marker"
    if ((signature[0] & 0xff) != 0x30 || (signature[1] & 0xff) != signature.length-3)
      return false;

    int lenR = signature[3] & 0xff;
    if (5 + lenR >= signature.length || lenR == 0)
      return false;
    int lenS = signature[5+lenR] & 0xff;
    if (lenR + lenS + 7 != signature.length || lenS == 0)
      return false;

    //    R value type mismatch          R value negative
    if (signature[4-2] != 0x02 || (signature[4] & 0x80) == 0x80)
      return false;
    if (lenR > 1 && signature[4] == 0x00 && (signature[4+1] & 0x80) != 0x80)
      return false; // R value excessively padded

    //       S value type mismatch                    S value negative
    if (signature[6 + lenR - 2] != 0x02 || (signature[6 + lenR] & 0x80) == 0x80)
      return false;
    if (lenS > 1 && signature[6 + lenR] == 0x00 && (signature[6 + lenR + 1] & 0x80) != 0x80)
      return false; // S value excessively padded

    return true;
  }
  
  Uint8List _serialize() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(encodeToDER())
      ..add(_sigHashFlags));
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    // no lazy deserialization implemented
  }
  
}

class SigHash {
  static const SigHash ALL    = const SigHash._(1);
  static const SigHash NONE   = const SigHash._(2);
  static const SigHash SINGLE = const SigHash._(3);
  
  static const int ANYONE_CAN_PAY = 0x80; 
  
  final int value;
  
  const SigHash._(int this.value);
  
  static int sigHashFlagsValue(SigHash sh, bool anyoneCanPay) {
    int val = sh.value;
    if(anyoneCanPay)
      val |= ANYONE_CAN_PAY;
    return val;
  }
}