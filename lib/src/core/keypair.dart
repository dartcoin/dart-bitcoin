part of dartcoin;

class KeyPair {
  
  static final ECCurve _CURVE = new fp.ECCurve(
    new BigInteger("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"), //q
    new BigInteger("0000000000000000000000000000000000000000000000000000000000000000"), //a
    new BigInteger("0000000000000000000000000000000000000000000000000000000000000007") //b
  );
  
  static final ECDomainParameters _ECPARAMS = new ECDomainParametersImpl("secp256k1", 
      _CURVE, 
      _CURVE.decodePoint( new BigInteger("0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8").toByteArray() ), //G
      new BigInteger("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"), //n
      new BigInteger("01") //h
  );
  
  static final BigInteger _HALF_CURVE_ORDER = new BigInteger("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141").shiftRight(1);
  
  static final SecureRandom _secureRandom = new AutoSeedBlockCtrRandom(new AESFastEngine());
  
  BigInteger _priv;
  Uint8List _pub;
  // chache
  Uint8List _pubKeyHash;
  
  // encrypted private keys
  EncryptedPrivateKey _encryptedPrivateKey;
  KeyCrypter _keyCrypter;
  
  /**
   * Create a keypair from a private or public key.
   * 
   * Keys can either be of the type bignum.BigInteger or Uint8List.
   * 
   * Only type checks are performed on the data, no other validation is done.
   * 
   */
  factory KeyPair([dynamic publicKey, dynamic privateKey, bool compressed = true]) {
    if(publicKey == null && privateKey == null) return new KeyPair.generate();
    if(privateKey is Uint8List) {
      privateKey = new BigInteger.fromBytes(1, privateKey);
    }
    if(privateKey is BigInteger) {
      if(!(publicKey is Uint8List))
        publicKey = publicKeyFromPrivateKey(privateKey, compressed);
      return new KeyPair._internal(privateKey, publicKey);
    }
    if(publicKey is BigInteger)
      publicKey = Utils.bigIntegerToBytes(publicKey, 65);
    if(publicKey is Uint8List && privateKey == null)
      return new KeyPair._internal(null, publicKey);
    throw new Exception("The parameters were not of a usable type.");
  }
  
  factory KeyPair.encrypted(EncryptedPrivateKey encryptedPrivateKey, Uint8List publicKey, keyCrypter) {
    if(keyCrypter == null) throw new Exception("KeyCrypter should not be null!");
    KeyPair newKey = new KeyPair._internal(null, publicKey);
    newKey._encryptedPrivateKey = encryptedPrivateKey;
    newKey._keyCrypter = keyCrypter;
    return newKey;
  }
  
  /**
   * Intended for internal use only.
   */
  KeyPair._internal(BigInteger this._priv, Uint8List this._pub);
  
  /**
   * Generate a new random key pair.
   */
  factory KeyPair.generate() {
    //TODO
  }
  
  Uint8List get publicKey => _pub;
  
  Uint8List get pubKeyHash {
    if(_pubKeyHash == null)
      _pubKeyHash = Utils.sha256hash160(_pub);
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
    return _priv;
  }
  
  /**
   * Returns a 32 byte array containing the private key.
   */
  Uint8List get privateKeyBytes {
    return Utils.bigIntegerToBytes(_priv, 32);
  }
  
  bool get hasPrivKey => _priv != null;
  
  bool get isEncrypted {
    _encryptedPrivateKey != null && _keyCrypter != null;
  }
  
  EncryptedPrivateKey get encryptedPrivateKey {
    if(_encryptedPrivateKey == null) return null;
    return _encryptedPrivateKey.clone();
  }
  
  KeyCrypter get keyCrypter => _keyCrypter;
  
  /**
   * Generate the address that represents this keypair. 
   * 
   * If `params` is ommited, the MAINNET params will be used.
   */
  Address toAddress([NetworkParameters params]) {
    if(params == null)
      return new Address(Utils.sha256hash160(_pub));
    return new Address.withNetworkParameters(Utils.sha256hash160(_pub), params);
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer()
      ..write("pub:")
      ..write(Utils.bytesToHex(_pub));
    if(isEncrypted) sb.write(" encrypted");
    return sb.toString();
  }
  
  String toStringWithPrivateKey() {
    if(!hasPrivKey) return toString();
    StringBuffer sb = new StringBuffer()
      ..write(toString())
      ..write(" priv:")
      ..write(Utils.bytesToHex(_priv.toByteArray()));
    return sb.toString();
  }
  
  /**
   * This method irreversibly deletes the private key from memory.
   * The key will still be usable as a public key only.
   */
  void clearPrivateKey() {
    _priv = null;
    _encryptedPrivateKey.clear();
    _encryptedPrivateKey = null;
    _keyCrypter = null;
  }
  
  bool operator ==(KeyPair other) {
    if(!(other is KeyPair)) return false;
    if(identical(this, other)) return true;
    return Utils.equalLists(publicKey, other.publicKey);
  }
  
  int get hashCode {
    return (publicKey[0] & 0xff) | ((publicKey[1] & 0xff) << 8) | ((publicKey[2] & 0xff) << 16) | ((publicKey[3] & 0xff) << 24);
  }

  /**
   * Signs the given hash and returns the R and S components as BigIntegers. In the Bitcoin protocol, they are
   * usually encoded using DER format, so you want {@link com.google.bitcoin.core.ECKey.ECDSASignature#encodeToDER()}
   * instead. However sometimes the independent components can be useful, for instance, if you're doing to do further
   * EC maths on them.
  *
   * @param aesKey The AES key to use for decryption of the private key. If null then no decryption is required.
   */
  ECDSASignature sign(Sha256Hash input, [KeyParameter aesKey]) {
    // The private key bytes to use for signing.
    BigInteger privateKeyForSigning;

    if (isEncrypted) {
      // The private key needs decrypting before use.
      if (aesKey == null)
        throw new Exception("This ECKey is encrypted but no decryption key has been supplied.");

      if (keyCrypter == null)
        throw new Exception("There is no KeyCrypter to decrypt the private key for signing.");

      privateKeyForSigning = new BigInteger(1, keyCrypter.decrypt(_encryptedPrivateKey, aesKey));
      // Check encryption was correct.
      if (!Utils.equalLists(_pub, publicKeyFromPrivateKey(privateKeyForSigning, isCompressed)))
        throw new Exception("Could not decrypt bytes");
    } else {
      // No decryption of private key required.
      if (_priv == null)
        throw new Exception("This ECKey does not have the private key necessary for signing.");
      else
        privateKeyForSigning = _priv;
    }

    ECDSASigner signer = new ECDSASigner();
    PrivateKeyParameter privKey = new PrivateKeyParameter(new ECPrivateKey(privateKeyForSigning, _ECPARAMS));
    signer.init(true, privKey);
    ECSignature ecSig = signer.generateSignature(input.bytes);
    final ECDSASignature signature = new ECDSASignature(ecSig.r, ecSig.s);
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
    ECDSASigner signer = new ECDSASigner();
    PublicKeyParameter params = new PublicKeyParameter(new ECPublicKey(_ECPARAMS.curve.decodePoint(_pub), _ECPARAMS));
    signer.init(false, params);
    ECSignature ecSig = new ECSignature(signature.r, signature.s);
    return signer.verifySignature(data, ecSig);
  }

  /**
   * Verifies the given ASN.1 encoded ECDSA signature against a hash using the public key.
   */
  bool verifyASN1(Uint8List data, Uint8List signature, Uint8List pub) {
    return verify(data, new ECDSASignature.decodeFromDER(signature));
  }

  /**
   * Signs a text message using the standard Bitcoin messaging signing format and returns the signature as a base64
   * encoded string.
   */
  String signMessage(String message, [KeyParameter aesKey]) {
    if (_priv == null)
      throw new Exception("This ECKey does not have the private key necessary for signing.");
    Uint8List data = Utils.formatMessageForSigning(message);
    Sha256Hash hash = Sha256Hash.doubleDigest(data);
    ECDSASignature sig = sign(hash, aesKey);
    // Now we have to work backwards to figure out the recId needed to recover the signature.
    int recId = -1;
    for (int i = 0; i < 4; i++) {
      KeyPair k = recoverFromSignature(i, sig, hash, isCompressed);
      if (k != null && Utils.equalLists(k.publicKey, publicKey)) {
        recId = i;
        break;
      }
    }
    if (recId == -1)
      throw new Exception("Could not construct a recoverable key. This should never happen.");
    int headerByte = recId + 27 + (isCompressed ? 4 : 0);
    Uint8List sigData = new Uint8List(65);  // 1 header + 32 bytes for R + 32 bytes for S
    sigData[0] = headerByte;
    sigData.setRange(1,  1+32,  Utils.bigIntegerToBytes(sig.r, 32));
    sigData.setRange(33, 33+32, Utils.bigIntegerToBytes(sig.s, 32));
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
      throw new Exception("Signature truncated, expected 65 bytes and got ${signatureEncoded.length}");
    int header = signatureEncoded[0] & 0xFF;
    // The header byte: 0x1B = first key with even y, 0x1C = first key with odd y,
    //                  0x1D = second key with even y, 0x1E = second key with odd y
    if (header < 27 || header > 34)
      throw new Exception("Header byte out of range: $header");
    BigInteger r = new BigInteger.fromBytes(1, signatureEncoded.getRange(1, 33));
    BigInteger s = new BigInteger.fromBytes(1, signatureEncoded.getRange(33, 65));
    ECDSASignature sig = new ECDSASignature(r, s);
    Uint8List messageBytes = Utils.formatMessageForSigning(message);
    // Note that the C++ code doesn't actually seem to specify any character encoding. Presumably it's whatever
    // JSON-SPIRIT hands back. Assume UTF-8 for now.
    Sha256Hash messageHash = Sha256Hash.doubleDigest(messageBytes);
    bool compressed = false;
    if (header >= 31) {
      compressed = true;
      header -= 4;
    }
    int recId = header - 27;
    KeyPair key = KeyPair.recoverFromSignature(recId, sig, messageHash, compressed);
    if (key == null) //TODO
      throw new Exception("Could not recover public key from signature");
    return key;
  }

  /**
   * Convenience wrapper around KeyPair.signedMessageToKey(String, String).
   */
  bool verifyMessage(String message, String signatureBase64) {
    KeyPair key = KeyPair.signedMessageToKey(message, signatureBase64);
    return Utils.equalLists(key.publicKey, publicKey);
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
  static KeyPair recoverFromSignature(int recId, ECDSASignature sig, Sha256Hash message, [bool compressed = true]) {
    if(recId < 0) 
      throw new Exception("recId must be positive");
    if(sig.r.compareTo(BigInteger.ZERO) < 0 || sig.s.compareTo(BigInteger.ZERO) < 0)
      throw new Exception("r and s must be possitive");
    if(message == null)
      throw new Exception("Message is null");
    // 1.0 For j from 0 to h   (h == recId here and the loop is outside this function)
    //   1.1 Let x = r + jn
    BigInteger n = _ECPARAMS.n; // Curve order.
    BigInteger i = new BigInteger(recId / 2);
    BigInteger x = sig.r + ( i * n );
    //   1.2. Convert the integer x to an octet string X of length mlen using the conversion routine
    //        specified in Section 2.3.7, where mlen = ���(log2 p)/8��� or mlen = ���m/8���.
    //   1.3. Convert the octet string (16 set binary digits)||X to an elliptic curve point R using the
    //        conversion routine specified in Section 2.3.4. If this conversion routine outputs ���invalid���, then
    //        do another iteration of Step 1.
    //
    // More concisely, what these points mean is to use X as a compressed public key.
    fp.ECCurve curve = _CURVE;
    
    BigInteger prime = curve.q;  // Bouncy Castle is not consistent about the letter it uses for the prime.
    if (x.compareTo(prime) >= 0) {
      // Cannot have point co-ordinates larger than this as everything takes place modulo Q.
      return null;
    }
    // Compressed keys require you to know an extra bit of data about the y-coord as there are two possibilities.
    // So it's encoded in the recId.
    ECPoint R = _decompressKey(x, (recId & 1) == 1);
    //   1.4. If nR != point at infinity, then do another iteration of Step 1 (callers responsibility).
    if (!(R * n).isInfinity)
      return null;
    //   1.5. Compute e from M using Steps 2 and 3 of ECDSA signature verification.
    BigInteger e = new BigInteger.fromBytes(1, message.bytes);
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
    ECPoint p1 = _ECPARAMS.G * eInvrInv;
    ECPoint p2 = R * srInv;
    fp.ECPoint q = p2 + p1;
    if (compressed) {
      // We have to manually recompress the point as the compressed-ness gets lost when multiply() is used.
      q = new fp.ECPoint(curve, q.x, q.y, true);
    }
    return new KeyPair(null, q.getEncoded());
  }
  

  
  // **********************
  // ***** encryption *****
  // **********************
  
  /**
   * Create an encrypted private key with the keyCrypter and the AES key supplied.
   * This method returns a new encrypted key and leaves the original unchanged.
   * To be secure you need to clear the original, unencrypted private key bytes.
   */
  KeyPair encrypt(KeyCrypter keyCrypter, KeyParameter aesKey) {
    EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(privateKeyBytes, aesKey);
    return new KeyPair.encrypted(encryptedPrivateKey, publicKey, keyCrypter);
  }

  /**
   * Create a decrypted private key with the keyCrypter and AES key supplied. Note that if the aesKey is wrong, this
   * has some chance of throwing KeyCrypterException due to the corrupted padding that will result, but it can also
   * just yield a garbage key.
   */
  KeyPair decrypt(KeyCrypter keyCrypter, KeyParameter aesKey) {
    // Check that the keyCrypter matches the one used to encrypt the keys, if set.
    if (this.keyCrypter != null && this.keyCrypter != keyCrypter) {
      throw new Exception("The keyCrypter being used to decrypt the key is different to the one that was used to encrypt it");
    }
    Uint8List unencryptedPrivateKey = keyCrypter.decrypt(encryptedPrivateKey, aesKey);
    KeyPair key = new KeyPair(new BigInteger(1, unencryptedPrivateKey), null, isCompressed);
    if (!Utils.equalLists(key.publicKey, publicKey))
      throw new Exception("Provided AES key is wrong");
    return key;
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
  static bool encryptionIsReversible(KeyPair originalKey, KeyPair encryptedKey, KeyCrypter keyCrypter, KeyParameter aesKey) {
    KeyPair rebornUnencryptedKey = encryptedKey.decrypt(keyCrypter, aesKey);
    if (rebornUnencryptedKey == null)
      return false;
    Uint8List originalPrivateKeyBytes = originalKey.privateKeyBytes;
    if (originalPrivateKeyBytes != null) {
      if (rebornUnencryptedKey.privateKeyBytes == null)
        return false;
      if (originalPrivateKeyBytes.length != rebornUnencryptedKey.privateKeyBytes.length)
        return false;
      for (int i = 0; i < originalPrivateKeyBytes.length; i++) {
        if (originalPrivateKeyBytes[i] != rebornUnencryptedKey.privateKeyBytes[i]) {
          return false;
        }
      }
    }
    // Key can successfully be decrypted.
    return true;
  }
  
  
  // *****************************
  // ***** utility functions *****
  // *****************************
  
  /**
   * Retrieve the public key from the given private key.
   * Use `new BigInteger.fromBytes(signum, magnitude)` to convert a byte array into a BigInteger.
   */
  static Uint8List publicKeyFromPrivateKey(BigInteger privateKey, [bool compressed = true]) {
    ECPoint point = _ECPARAMS.G * privateKey;
    return point.getEncoded(compressed);
  }

  /**
   * Returns true if the given pubkey is canonical, i.e. the correct length taking into account compression.
   */
  static bool checkIsPubKeyCanonical(Uint8List pubKey) {
    if (pubKey.length < 33)
      return false;
    if (pubKey[0] == 0x04) {
      // Uncompressed pubkey
      if (pubKey.length != 65)
        return false;
    } else if (pubKey[0] == 0x02 || pubKey[0] == 0x03) {
      // Compressed pubkey
      if (pubKey.length != 33)
        return false;
    } else
      return false;
    return true;
  }

  /** Decompress a compressed public key (x co-ord and low-bit of y-coord). */
  static ECPoint _decompressKey(BigInteger xBN, bool yBit) {
    // This code is adapted from Bouncy Castle ECCurve.Fp.decodePoint(), but it wasn't easily re-used.
    fp.ECCurve curve = _CURVE;
    ECFieldElement x = new fp.ECFieldElement(curve.q, xBN);
    ECFieldElement alpha = x * (x.square() + curve.a) + curve.b;
    ECFieldElement beta = alpha.sqrt();
    // If we can't find a sqrt we haven't got a point on the curve - invalid inputs.
    if (beta == null)
      throw new Exception("Invalid point compression");
    if (beta.toBigInteger().testBit(0) == yBit) {
      return new fp.ECPoint(curve, x, beta, true);
    } else {
      fp.ECFieldElement y = new fp.ECFieldElement(curve.q, curve.q - beta.toBigInteger());
      return new fp.ECPoint(curve, x, y, true);
    }
  }
  
  //TODO
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
    /*try {
      ASN1InputStream decoder = new ASN1InputStream(asn1privkey);
      DLSequence seq = (DLSequence) decoder.readObject();
      checkArgument(seq.size() == 4, "Input does not appear to be an ASN.1 OpenSSL EC private key");
      checkArgument(((DERInteger) seq.getObjectAt(0)).getValue().equals(BigInteger.ONE),
      "Input is of wrong version");
      Object obj = seq.getObjectAt(1);
      byte[] bits = ((ASN1OctetString) obj).getOctets();
      decoder.close();
      return new BigInteger(1, bits);
    } catch (IOException e) {
      throw new RuntimeException(e);  // Cannot happen, reading from memory stream.
    }*/
  }
}


class EncryptedPrivateKey {
  Uint8List initialisationVector;
  Uint8List encryptedPrivateBytes;
  
  EncryptedPrivateKey(this.initialisationVector, this.encryptedPrivateBytes);
  
  EncryptedPrivateKey.copy(EncryptedPrivateKey key) : this(key.initialisationVector, key.encryptedPrivateBytes);
  
  EncryptedPrivateKey clone() => new EncryptedPrivateKey.copy(this);
  
  operator ==(EncryptedPrivateKey other) {
    if(!(other is EncryptedPrivateKey)) return false;
    if(identical(other, this)) return true;
    return initialisationVector == other.initialisationVector && encryptedPrivateBytes == other.encryptedPrivateBytes;
  }
  
  String toString() {
    return "EncryptedPrivateKey [initialisationVector=$initialisationVector, encryptedPrivateBytes=$encryptedPrivateBytes]";
  }
  
  void clear() {
    initialisationVector = null;
    encryptedPrivateBytes = null;
  }
}


//TODO replace with cipher.ECSignature as soon as it supports DER encoding and ensuring canonical
class ECDSASignature {
  BigInteger r, s;
  
  ECDSASignature(this.r, this.s);
  
  void ensureCanonical() {
    if(s > KeyPair._HALF_CURVE_ORDER) {
      // The order of the curve is the number of valid points that exist on that curve. If S is in the upper
      // half of the number of valid points, then bring it back to the lower half. Otherwise, imagine that
      //    N = 10
      //    s = 8, so (-8 % 10 == 2) thus both (r, 8) and (r, 2) are valid solutions.
      //    10 - 8 == 2, giving us always the latter solution, which is canonical.
      s = KeyPair._ECPARAMS.n - s;
    }
  }
  
  Uint8List encodeToDER() {
    //TODO
  }
  
  ECDSASignature.decodeFromDER(Uint8List bytes) {
    //TODO
  }
}




















