part of bitcoin.core;

class KeyPair {
  //TODO remove once tested
  // EC curve definition "secp256k1"
//  static final _ec_q = new BigInteger("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", 16);
//  static final _ec_a = new BigInteger("0", 16);
//  static final _ec_b = new BigInteger("7", 16);
//  static final _ec_g = new BigInteger("0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8", 16);
//  static final _ec_n = new BigInteger("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", 16);
//  static final _ec_h = new BigInteger("1", 16);
//  static final ECCurve _EC_CURVE = new fp.ECCurve(_ec_q, _ec_a, _ec_b);
//  static final ECDomainParameters EC_PARAMS = new ECDomainParametersImpl(
//      "secp256k1", _EC_CURVE, _EC_CURVE.decodePoint(_ec_g.toByteArray()), _ec_n, _ec_h, null);

  static final ECDomainParameters EC_PARAMS = new ECCurve_secp256k1();

  static final BigInteger HALF_CURVE_ORDER = EC_PARAMS.n.shiftRight(1);

  // instance variables
  BigInteger _priv;
  Uint8List _pub;
  // chache
  Hash160 _pubKeyHash;

  // encrypted private key
  EncryptedPrivateKey _encryptedPrivateKey;
  KeyCrypter _keyCrypter;

  /**
   * Create a new public key.
   */
  factory KeyPair.public(Uint8List publicKey) {
    if (publicKey is! Uint8List) throw new ArgumentError("Public key must be of type Uint8List");
    return new KeyPair._internal(null, publicKey);
  }

  /**
   * Create a new private key.
   *
   * Pass either a [Uint8List] or [BigInteger] to use as a private key.
   */
  factory KeyPair.private(dynamic privateKey, {Uint8List publicKey, bool compressed: true}) {
    if (privateKey is Uint8List) privateKey = new BigInteger.fromBytes(1, privateKey);
    if (privateKey is! BigInteger)
      throw new ArgumentError("Private key must be either of type BigInteger or Uint8List");
    if (publicKey != null && publicKey is! Uint8List)
      throw new ArgumentError("Public key must be of type Uint8List");
    if (publicKey == null) publicKey = publicKeyFromPrivateKey(privateKey, compressed);
    return new KeyPair._internal(privateKey, publicKey);
  }

  /**
   * Create a new encrypted private key
   */
  factory KeyPair.encrypted(
      EncryptedPrivateKey encryptedPrivateKey, Uint8List publicKey, KeyCrypter keyCrypter) {
    if (keyCrypter == null) throw new Exception("KeyCrypter should not be null!");
    KeyPair newKey = new KeyPair._internal(null, publicKey)
      .._encryptedPrivateKey = encryptedPrivateKey
      .._keyCrypter = keyCrypter;
    return newKey;
  }

  /**
   * Generate a new random key pair.
   *
   * Due to lack of real built-in Entropy sources in Dart, entropy must be provided.
   * This will be changed as soon as good entropy is available.
   */
  factory KeyPair.generate([Uint8List entropy]) {
    // ensure that at least 50 bytes of entropy are available
    Random rand = new Random(); //TODO make real entropy
    BigInteger pk;
    do {
      var buffer = new bytes.Buffer();
      buffer.add(entropy ?? []);
      if (buffer.length < 50) {
        buffer.add(new List.generate(50 - buffer.length, (_) => rand.nextInt(255)));
      }
      entropy = crypto.doubleDigest(buffer.asBytes());
      pk = new BigInteger.fromBytes(1, entropy.sublist(0, EC_PARAMS.n.bitLength() ~/ 8));
    } while (pk == BigInteger.ZERO || pk >= EC_PARAMS.n);
    return new KeyPair._internal(pk, publicKeyFromPrivateKey(pk, true));
  }

  /**
   * Create the private key encoded in [asn1bytes].
   *
   * For more info, see the definition of the ASN.1 format for EC private keys
   * in the OpenSSL source code in ec_asn1.c.
   */
  factory KeyPair.fromASN1(Uint8List asn1bytes) {
    return new KeyPair.private(extractPrivateKeyFromASN1(asn1bytes));
  }

  /**
   * Intended for internal use only.
   */
  KeyPair._internal(BigInteger this._priv, Uint8List this._pub);

  Uint8List get publicKey => new Uint8List.fromList(_pub);

  Hash160 get pubKeyHash {
    if (_pubKeyHash == null) _pubKeyHash = new Hash160(crypto.sha256hash160(_pub));
    return _pubKeyHash;
  }

  /**
   * Returns whether this key is using the compressed form or not. Compressed pubkeys are only 33 bytes, not 64.
   */
  bool get isCompressed {
    return _pub.length == 33;
  }

  /**
   * Returns true if this pubkey is canonical, i.e. the correct length taking into account compression.
   */
  bool get isPubKeyCanonical {
    return checkIsPubKeyCanonical(_pub);
  }

  /**
   * 32-bytes private key
   */
  BigInteger get privateKey {
    if (_priv == null) return null;
    BigInteger copy = new BigInteger();
    _priv.copyTo(copy);
    return copy;
  }

  /**
   * Returns a 32 byte array containing the private key.
   */
  Uint8List get privateKeyBytes {
    if (_priv == null) return null;
    return utils.bigIntegerToBytes(_priv, 32);
  }

  /**
   * Returns true if this [KeyPair] contains an unencrypted private key.
   *
   * Use [isEncrypted] to check if it does have an encrypted key.
   */
  bool get hasPrivateKey => _priv != null;

  bool get isEncrypted => _encryptedPrivateKey != null && _keyCrypter != null;

  EncryptedPrivateKey get encryptedPrivateKey => _encryptedPrivateKey;

  KeyCrypter get keyCrypter => _keyCrypter;

  /**
   * Generate the address that represents this keypair. 
   * 
   * If [params] is ommited, the MAINNET params will be used.
   */
  Address getAddress([NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      new Address.fromHash160(pubKeyHash, params.addressHeader);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer()..write("pub:")..write(CryptoUtils.bytesToHex(_pub));
    if (isEncrypted) sb.write(" encrypted");
    return sb.toString();
  }

  String toStringWithPrivateKey() {
    if (!hasPrivateKey) return toString();
    StringBuffer sb = new StringBuffer()
      ..write(toString())
      ..write(" priv:")
      ..write(CryptoUtils.bytesToHex(_priv.toByteArray()));
    return sb.toString();
  }

  /**
   * This method irreversibly deletes the private key from memory,
   * also when it is an encrypted key.
   *
   * The [KeyPair] will still be usable as a public key only.
   */
  void clearPrivateKey() {
    _priv = null;
    if (_encryptedPrivateKey != null) {
      _encryptedPrivateKey.clear();
      _encryptedPrivateKey = null;
    }
    _keyCrypter = null;
  }

  bool operator ==(KeyPair other) {
    if (other is! KeyPair) return false;
    return utils.equalLists(_pub, other._pub);
  }

  int get hashCode {
    return (_pub[0] & 0xff) |
        ((_pub[1] & 0xff) << 8) |
        ((_pub[2] & 0xff) << 16) |
        ((_pub[3] & 0xff) << 24);
  }

  /**
   * Signs the given hash and returns the R and S components as BigIntegers. In the Bitcoin protocol, they are
   * usually encoded using DER format, so you want [ECDSASignature#encodeToDER()]
   * instead. However sometimes the independent components can be useful, for instance, if you're doing to do further
   * EC maths on them.
  *
   * @param aesKey The AES key to use for decryption of the private key. If null then no decryption is required.
   */
  ECDSASignature sign(Hash256 input, [KeyParameter aesKey]) {
    // The private key bytes to use for signing.
    BigInteger privateKeyForSigning;

    if (isEncrypted) {
      // The private key needs decrypting before use.
      if (aesKey == null)
        throw new Exception("This ECKey is encrypted but no decryption key has been supplied.");

      if (keyCrypter == null)
        throw new Exception("There is no KeyCrypter to decrypt the private key for signing.");

      privateKeyForSigning =
          new BigInteger.fromBytes(1, keyCrypter.decrypt(_encryptedPrivateKey, aesKey));
      // Check encryption was correct.
      if (!utils.equalLists(_pub, publicKeyFromPrivateKey(privateKeyForSigning, isCompressed)))
        throw new Exception("Could not decrypt bytes");
    } else {
      // No decryption of private key required.
      if (!hasPrivateKey)
        throw new Exception("This KeyPair does not have the private key necessary for signing.");
      else
        privateKeyForSigning = _priv;
    }

    ECDSASigner signer = _createSigner(new ECPrivateKey(privateKeyForSigning, EC_PARAMS), true);
    ECSignature ecSig = signer.generateSignature(input.asBytes());
    ECDSASignature signature = new ECDSASignature(ecSig.r, ecSig.s);
    signature.ensureCanonical();
    return signature;
  }

  /**
   * <p>Verifies the given ECDSA signature against the message bytes using the public key bytes.</p>
   * 
   * <p>When using native ECDSA verification, data must be 32 bytes, and no element may be
   * larger than 520 bytes.</p>
   */
  bool verify(Uint8List data, ECDSASignature signature) {
    return verifySignatureForPubkey(data, signature, _pub);
  }

  static bool verifySignatureForPubkey(Uint8List data, ECDSASignature signature, Uint8List pubkey) {
    ECDSASigner signer =
        _createSigner(new ECPublicKey(EC_PARAMS.curve.decodePoint(pubkey), EC_PARAMS), false);
    ECSignature ecSig = new ECSignature(signature.r, signature.s);
    return signer.verifySignature(data, ecSig);
  }

  /**
   * Signs a text message using the standard Bitcoin messaging signing format and returns the signature as a base64
   * encoded string.
   */
  String signMessage(String message, [KeyParameter aesKey]) {
    if (_priv == null)
      throw new StateError("This ECKey does not have the private key necessary for signing.");
    Uint8List data = utils.formatMessageForSigning(message);
    Hash256 hash = new Hash256(crypto.doubleDigest(data));
    ECDSASignature sig = sign(hash, aesKey);
    // Now we have to work backwards to figure out the recId needed to recover the signature.
    int recId = -1;
    for (int i = 0; i < 4; i++) {
      KeyPair k = recoverFromSignature(i, sig, hash, isCompressed);
      if (k != null && utils.equalLists(k._pub, _pub)) {
        recId = i;
        break;
      }
    }
    if (recId == -1)
      throw new Exception("Could not construct a recoverable key. This should never happen.");
    int headerByte = recId + 27 + (isCompressed ? 4 : 0);
    Uint8List sigData = new Uint8List(65);
    // 1 header + 32 bytes for R + 32 bytes for S
    sigData[0] = headerByte;
    sigData.setRange(1, 1 + 32, utils.bigIntegerToBytes(sig.r, 32));
    sigData.setRange(33, 33 + 32, utils.bigIntegerToBytes(sig.s, 32));
    return CryptoUtils.bytesToBase64(sigData);
  }

  /**
   * Given an arbitrary piece of text and a Bitcoin-format message signature encoded in base64, returns an ECKey
   * containing the public key that was used to sign it. This can then be compared to the expected public key to
   * determine if the signature was correct. These sorts of signatures are compatible with the Bitcoin-Qt/bitcoind
   * format generated by signmessage/verifymessage RPCs and GUI menu options. They are intended for humans to verify
   * their communications with each other, hence the base64 format and the fact that the input is text.
   *
   * @param message Some piece of human readable text.
   * @param signatureBase64 The Bitcoin-format message signature in base64
   * @throws SignatureException If the public key could not be recovered or if there was a signature format error.
   */
  static KeyPair signedMessageToKey(String message, String signatureBase64) {
    Uint8List signatureEncoded = CryptoUtils.base64StringToBytes(signatureBase64);
    // Parse the signature bytes into r/s and the selector value.
    if (signatureEncoded.length < 65)
      throw new Exception(
          "Signature truncated, expected 65 bytes and got ${signatureEncoded.length}");
    int header = signatureEncoded[0] & 0xFF;
    // The header byte: 0x1B = first key with even y, 0x1C = first key with odd y,
    //                  0x1D = second key with even y, 0x1E = second key with odd y
    if (header < 27 || header > 34) throw new Exception("Header byte out of range: $header");
    BigInteger r = new BigInteger.fromBytes(1, new List.from(signatureEncoded.getRange(1, 33)));
    BigInteger s = new BigInteger.fromBytes(1, new List.from(signatureEncoded.getRange(33, 65)));
    ECDSASignature sig = new ECDSASignature(r, s);
    Uint8List messageBytes = utils.formatMessageForSigning(message);
    // Note that the C++ code doesn't actually seem to specify any character encoding. Presumably it's whatever
    // JSON-SPIRIT hands back. Assume UTF-8 for now.
    Hash256 messageHash = new Hash256(crypto.doubleDigest(messageBytes));
    bool compressed = false;
    if (header >= 31) {
      compressed = true;
      header -= 4;
    }
    int recId = header - 27;
    KeyPair key = KeyPair.recoverFromSignature(recId, sig, messageHash, compressed);
    if (key == null) throw new Exception("Could not recover public key from signature");
    return key;
  }

  /**
   * Convenience wrapper around KeyPair.signedMessageToKey(String, String).
   */
  bool verifyMessage(String message, String signatureBase64) {
    KeyPair key = KeyPair.signedMessageToKey(message, signatureBase64);
    return utils.equalLists(key._pub, _pub);
  }

  static ECDSASigner _createSigner(dynamic key, bool forSigning) {
    var params = forSigning ? new PrivateKeyParameter(key) : new PublicKeyParameter(key);
    Mac signerMac = new HMac(new SHA256Digest(), 64);
    // = new Mac("SHA-256/HMAC")
    return new ECDSASigner(null, signerMac)..init(forSigning, params);
  }

  /**
   * <p>Given the components of a signature and a selector value, recover and return the public key
   * that generated the signature according to the algorithm in SEC1v2 section 4.1.6.</p>
   *
   * <p>The recId is an index from 0 to 3 which indicates which of the 4 possible keys is the correct one. Because
   * the key recovery operation yields multiple potential keys, the correct key must either be stored alongside the
   * signature, or you must be willing to try each recId in turn until you find one that outputs the key you are
   * expecting.</p>
   *
   * <p>If this method returns null it means recovery was not possible and recId should be iterated.</p>
   *
   * <p>Given the above two points, a correct usage of this method is inside a for loop from 0 to 3, and if the
   * output is null OR a key that is not the one you expect, you try again with the next recId.</p>
   *
   * @param recId Which possible key to recover.
   * @param sig the R and S components of the signature, wrapped.
   * @param message Hash of the data that was signed.
   * @param compressed Whether or not the original pubkey was compressed.
   * @return An ECKey containing only the public part, or null if recovery wasn't possible.
   */
  static KeyPair recoverFromSignature(int recId, ECDSASignature sig, Hash256 message,
      [bool compressed = true]) {
    if (recId < 0) throw new Exception("recId must be positive");
    if (sig.r.compareTo(BigInteger.ZERO) < 0 || sig.s.compareTo(BigInteger.ZERO) < 0)
      throw new Exception("r and s must be possitive");
    if (message == null) throw new Exception("Message is null");
    // 1.0 For j from 0 to h   (h == recId here and the loop is outside this function)
    //   1.1 Let x = r + jn
    BigInteger n = EC_PARAMS.n; // Curve order.
    BigInteger i = new BigInteger(recId / 2);
    BigInteger x = sig.r + (i * n);
    //   1.2. Convert the integer x to an octet string X of length mlen using the conversion routine
    //        specified in Section 2.3.7, where mlen = [omitted due to weird encoding]
    //   1.3. Convert the octet string (16 set binary digits)||X to an elliptic curve point R using the
    //        conversion routine specified in Section 2.3.4. If this conversion routine outputs [omitted due to weird encoding]
    //        do another iteration of Step 1.
    //
    // More concisely, what these points mean is to use X as a compressed public key.
    fp.ECCurve curve = EC_PARAMS.curve;

    BigInteger prime = curve.q;
    // Bouncy Castle is not consistent about the letter it uses for the prime.
    if (x.compareTo(prime) >= 0) {
      // Cannot have point co-ordinates larger than this as everything takes place modulo Q.
      return null;
    }
    // Compressed keys require you to know an extra bit of data about the y-coord as there are two possibilities.
    // So it's encoded in the recId.
    ECPoint R = _decompressKey(x, (recId & 1) == 1);
    //   1.4. If nR != point at infinity, then do another iteration of Step 1 (callers responsibility).
    if (!(R * n).isInfinity) return null;
    //   1.5. Compute e from M using Steps 2 and 3 of ECDSA signature verification.
    BigInteger e = message.asBigInteger();
    //   1.6. For k from 1 to 2 do the following.   (loop is outside this function via iterating recId)
    //   1.6.1. Compute a candidate public key as:
    //               Q = mi(r) * (sR - eG)
    //
    // Where mi(x) is the modular multiplicative inverse. We transform this into the following:
    //               Q = (mi(r) * s ** R) + (mi(r) * -e ** G)
    // Where -e is the modular additive inverse of e, that is z such that z + e = 0 (mod n). In the above equation
    // ** is point multiplication and + is point addition (the EC group operator).
    //
    // We can find the additive inverse by subtracting e from zero then taking the mod. For example the additive
    // inverse of 3 modulo 11 is 8 because 3 + 8 mod 11 = 0, and -3 mod 11 = 8.
    BigInteger eInv = BigInteger.ZERO.subtract(e).mod(n);
    BigInteger rInv = sig.r.modInverse(n);
    BigInteger srInv = rInv.multiply(sig.s).mod(n);
    BigInteger eInvrInv = rInv.multiply(eInv).mod(n);
    ECPoint p1 = EC_PARAMS.G * eInvrInv;
    ECPoint p2 = R * srInv;
    fp.ECPoint q = p2 + p1;
    if (compressed) {
      // We have to manually recompress the point as the compressed-ness gets lost when multiply() is used.
      q = new fp.ECPoint(curve, q.x, q.y, true);
    }
    return new KeyPair.public(q.getEncoded());
  }

  // **********************
  // ***** encryption *****
  // **********************

  /**
   * Create an encrypted private key with the keyCrypter and the AES key supplied.
   * This method returns a new encrypted key and leaves the original unchanged.
   * To be secure you need to clear the original, unencrypted private key bytes.
   */
  KeyPair encrypt(KeyCrypter keyCrypter, KeyParameter encryptionKey) {
    if (isEncrypted) throw new Exception("Key already encrypted");
    EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(privateKeyBytes, encryptionKey);
    return new KeyPair.encrypted(encryptedPrivateKey, _pub, keyCrypter);
  }

  KeyPair encryptWithPassphrase(KeyCrypter keyCrypter, String passphrase) {
    return encrypt(keyCrypter, keyCrypter.deriveKey(passphrase));
  }

  /**
   * Create a decrypted private key with the keyCrypter and AES key supplied. Note that if the aesKey is wrong, this
   * has some chance of throwing KeyCrypterException due to the corrupted padding that will result, but it can also
   * just yield a garbage key.
   */
  KeyPair decrypt(KeyCrypter keyCrypter, KeyParameter decryptionKey) {
    if (!isEncrypted) throw new Exception("Key is not encrypted");
    // Check that the keyCrypter matches the one used to encrypt the keys, if set.
    if (this.keyCrypter != null && this.keyCrypter != keyCrypter) {
      throw new Exception(
          "The keyCrypter being used to decrypt the key is different to the one that was used to encrypt it");
    }
    Uint8List unencryptedPrivateKey = keyCrypter.decrypt(encryptedPrivateKey, decryptionKey);
    KeyPair key = new KeyPair.private(new BigInteger.fromBytes(1, unencryptedPrivateKey),
        compressed: isCompressed);
    if (!utils.equalLists(key._pub, _pub)) throw new ArgumentError("Provided AES key is wrong");
    return key;
  }

  KeyPair decryptWithPassphrase(KeyCrypter keyCrypter, String passphrase) {
    return decrypt(keyCrypter, keyCrypter.deriveKey(passphrase));
  }

  /**
   * Copied from bitcoinj:
   * 
   * Check that it is possible to decrypt the key with the keyCrypter and that the original key is returned.
   *
   * Because it is a critical failure if the private keys cannot be decrypted successfully (resulting of loss of all bitcoins controlled
   * by the private key) you can use this method to check when you *encrypt* a wallet that it can definitely be decrypted successfully.
   * See {@link Wallet#encrypt(KeyCrypter keyCrypter, KeyParameter aesKey)} for example usage.
   */
  static bool encryptionIsReversible(
      KeyPair originalKey, KeyPair encryptedKey, KeyCrypter keyCrypter, KeyParameter aesKey) {
    if (originalKey == null || !originalKey.hasPrivateKey)
      throw new ArgumentError("The original key provided is not a private key");
    try {
      KeyPair rebornUnencryptedKey = encryptedKey.decrypt(keyCrypter, aesKey);
      if (rebornUnencryptedKey == null || rebornUnencryptedKey.privateKeyBytes == null)
        return false;
      return utils.equalLists(originalKey.privateKeyBytes, rebornUnencryptedKey.privateKeyBytes);
    } on KeyCrypterException {
      return false;
    }
  }

  // *****************************
  // ***** utility functions *****
  // *****************************

  /**
   * Retrieve the public key from the given private key.
   * Use `new BigInteger.fromBytes(signum, magnitude)` to convert a byte array into a BigInteger.
   */
  static Uint8List publicKeyFromPrivateKey(BigInteger privateKey, [bool compressed = false]) {
    ECPoint point = EC_PARAMS.G * privateKey;
    return point.getEncoded(compressed);
  }

  /**
   * Returns true if the given pubkey is canonical, i.e. the correct length taking into account compression.
   */
  static bool checkIsPubKeyCanonical(Uint8List pubKey) {
    if (pubKey.length < 33) return false;
    if (pubKey[0] == 0x04) {
      // Uncompressed pubkey
      if (pubKey.length != 65) return false;
    } else {
      if (pubKey[0] == 0x02 || pubKey[0] == 0x03) {
        // Compressed pubkey
        if (pubKey.length != 33) return false;
      } else {
        return false;
      }
    }
    return true;
  }

  /** Decompress a compressed public key (x co-ord and low-bit of y-coord). */
  static ECPoint _decompressKey(BigInteger xBN, bool yBit) {
    // This code is adapted from Bouncy Castle ECCurve.Fp.decodePoint(), but it wasn't easily re-used.
    fp.ECCurve curve = EC_PARAMS.curve;
    ECFieldElement x = new fp.ECFieldElement(curve.q, xBN);
    ECFieldElement alpha = x * (x.square() + curve.a) + curve.b;
    ECFieldElement beta = alpha.sqrt();
    // If we can't find a sqrt we haven't got a point on the curve - invalid inputs.
    if (beta == null) throw new Exception("Invalid point compression");
    if (beta.toBigInteger().testBit(0) == yBit) {
      return new fp.ECPoint(curve, x, beta, true);
    } else {
      fp.ECFieldElement y = new fp.ECFieldElement(curve.q, curve.q - beta.toBigInteger());
      return new fp.ECPoint(curve, x, y, true);
    }
  }

  static BigInteger extractPrivateKeyFromASN1(Uint8List asn1privkey) {
    // To understand this code, see the definition of the ASN.1 format for EC private keys in the OpenSSL source
    // code in ec_asn1.c:
    //
    // ASN1_SEQUENCE(EC_PRIVATEKEY) = {
    //   ASN1_SIMPLE(EC_PRIVATEKEY, version, LONG),
    //   ASN1_SIMPLE(EC_PRIVATEKEY, privateKey, ASN1_OCTET_STRING),
    //   ASN1_EXP_OPT(EC_PRIVATEKEY, parameters, ECPKPARAMETERS, 0),
    //   ASN1_EXP_OPT(EC_PRIVATEKEY, publicKey, ASN1_BIT_STRING, 1)
    // } ASN1_SEQUENCE_END(EC_PRIVATEKEY)
    //
    ASN1Parser parser = new ASN1Parser(asn1privkey);
    ASN1Sequence seq = parser.nextObject() as ASN1Sequence;
    if (seq is! ASN1Sequence || seq.elements.length != 4)
      throw new ArgumentError("Priv key was not encoded as a Sequence with 4 elements.");
    BigInteger version = (seq.elements[0] as ASN1Integer).valueAsBigInteger;
    if (version != BigInteger.ONE)
      throw new ArgumentError("The private is encoded using a different encoding version.");
    Uint8List bits = (seq.elements[1] as ASN1OctetString).octets;
    return new BigInteger.fromBytes(1, bits);
  }

  /**
   * Not complete: the curve is not yet included and replaced by a 0 integer
   */
  //TODO complete when cipher supports encoding curves to ASN1 primitives
  Uint8List toASN1() {
    if (!hasPrivateKey) throw new Exception("KeyPair has no private key!");
    ASN1Sequence seq = new ASN1Sequence()
      ..add(new ASN1Integer(1))
      ..add(new ASN1OctetString(privateKeyBytes))
      ..add(new ASN1Integer(0)) // dummy
      ..add(new ASN1BitString(_pub, tag: 1));
    return seq.encodedBytes;
  }
}

class ECDSASignature {
  BigInteger r;
  BigInteger s;

  ECDSASignature(BigInteger this.r, BigInteger this.s);

  void ensureCanonical() {
    if (s > KeyPair.HALF_CURVE_ORDER) {
      // The order of the curve is the number of valid points that exist on that curve. If S is in the upper
      // half of the number of valid points, then bring it back to the lower half. Otherwise, imagine that
      //    N = 10
      //    s = 8, so (-8 % 10 == 2) thus both (r, 8) and (r, 2) are valid solutions.
      //    10 - 8 == 2, giving us always the latter solution, which is canonical.
      s = KeyPair.EC_PARAMS.n - s;
    }
  }

  Uint8List encodeToDER() {
    ASN1Sequence seq = new ASN1Sequence();
    seq.add(new ASN1Integer(r));
    seq.add(new ASN1Integer(s));
    return seq.encodedBytes;
  }

  factory ECDSASignature.fromDER(Uint8List bytes) {
    ASN1Parser parser = new ASN1Parser(bytes);
    ASN1Sequence seq = parser.nextObject() as ASN1Sequence;
    BigInteger r = (seq.elements[0] as ASN1Integer).valueAsPositiveBigInteger;
    BigInteger s = (seq.elements[1] as ASN1Integer).valueAsPositiveBigInteger;
    return new ECDSASignature(r, s);
  }
}
