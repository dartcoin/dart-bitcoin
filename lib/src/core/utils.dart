part of dartcoin;


class Utils {
  
  /**
   * Calculates the SHA-256 hash of the input data.
   */
  static Uint8List singleDigest(Uint8List input) {
    SHA256 digest = new SHA256();
    digest.add(input);
    return digest.close();
  }
  
  /**
   * Calculates the double-round SHA-256 hash of the input data.
   */
  static Uint8List doubleDigest(Uint8List input) {
    SHA256 digest = new SHA256();
    digest.add(input);
    Uint8List tmp = digest.close();
    digest = digest.newInstance();
    digest.add(tmp);
    return digest.close();
  }
  
  /**
   * Calculates the RIPEMD-160 hash of the given input.
   */
  static Uint8List ripemd160Digest(Uint8List input) {
    RIPEMD160Digest digest = new RIPEMD160Digest();
    digest.update(input, 0, input.length);
    digest.finish();
    Uint8List result = new List(20);
    digest.doFinal(result, 0);
    return result;
  }
  
  /**
   * Calculates the RIPEMD-160 hash of the SHA-256 hash of the input.
   * This is used to convert an ECDSA public key to a Bitcoin address.
   */
  static Uint8List sha256hash160(Uint8List input) {
    return ripemd160Digest(singleDigest(input));
  }
  
  /**
   * Converts a list of bytes to a hex string.
   * 
   * (Just a warpper for the crypto:CryptoUtils.bytesToHex() method.)
   */
  static String bytesToHex(Uint8List bytes) {
    return CryptoUtils.bytesToHex(bytes);
  }
  
  /**
   * Converts a hex string to a list of bytes.
   */
  static String _BYTE_ALPHABET = "0123456789ABCDEF";
  static Uint8List hexToBytes(String hex) {
    hex = hex.toUpperCase();
    if(hex.length % 2 != 0) {
      hex = "0" + hex;
    }
    Uint8List result = new List();
    while(hex.length > 0) {
      String byte = hex.substring(0, 2);
      hex = hex.substring(2, hex.length);
      
      int value = (_BYTE_ALPHABET.indexOf(byte[0]) << 8) //= byte[0] * 16 
          + _BYTE_ALPHABET.indexOf(byte[1]);
      result.add(value);
    }
    return result;
  }
  
  /**
   * Compare two lists, returns true if lists contain the same elements.
   * 
   * "==" operator is used to compare the lists.
   */
  static bool equalLists(List list1, List list2) {
    if(list1.length != list2.length) {
      return false;
    }
    for(int i = 0 ; i < list1.length ; i++) {
      if(list1[i] != list2[i]) {
        return false;
      }
    }
    return true;
  }
  
  /**
   * Converts the integer to a byte array in little endian. Ony positive integers allowed.
   */
  static Uint8List intToBytesLE(int val, [int size = -1]) {
    if(val < 0) throw new Exception("Only positive values allowed.");
    Uint8List result = new List();
    while(val > 0) {
      int mod = val % 256;
      val = val >> 8;
      result.add(mod);
    }
    if(size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
    while(result.length < size) result.add(0);
    return result;
  }
  
  /**
   * Converts the integer to a byte array in big endian. Ony positive integers allowed.
   */
  static Uint8List intToBytesBE(int val, [int size = -1]) {
    if(val < 0) throw new Exception("Only positive values allowed.");
    Uint8List result = new List();
    while(val > 0) {
      int mod = val % 256;
      val = val >> 8;
      result.insert(0, mod);
    }
    if(size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
    while(result.length < size) result.insert(0, 0);
    return result;
  }
}