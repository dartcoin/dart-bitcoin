part of dartcoin.core;

class Utils {
  
  /**
   * Calculates the SHA-256 hash of the input data.
   */
  static Uint8List singleDigest(Uint8List input) {
    SHA256 digest = new SHA256();
    digest.add(input);
    return new Uint8List.fromList(digest.close());
  }
  
  /**
   * Calculates the double-round SHA-256 hash of the input data.
   */
  static Uint8List doubleDigest(Uint8List input) {
    SHA256 digest = new SHA256();
    digest.add(input);
    SHA256 digest2 = new SHA256()
      ..add(digest.close());
    return new Uint8List.fromList(digest2.close());
  }
  
  /**
   * Calculates the double-round SHA-256 hash of the input data concatenated together.
   */
  static Uint8List doubleDigestTwoInputs(Uint8List input1, Uint8List input2) {
    SHA256 digest = new SHA256()
      ..add(input1)
      ..add(input2);
    SHA256 digest2 = new SHA256()
      ..add(digest.close());
    return new Uint8List.fromList(digest2.close());
  }
  
  /**
   * Calculates the RIPEMD-160 hash of the given input.
   */
  static Uint8List ripemd160Digest(Uint8List input) {
    RIPEMD160Digest digest = new RIPEMD160Digest();
    digest.update(input, 0, input.length);
    Uint8List result = new Uint8List(20);
    digest.doFinal(result, 0);
    return result;
  }
  
  /**
   * Calculates the SHA-1 hash of the given input.
   */
  static Uint8List sha1Digest(Uint8List input) {
    SHA1 digest = new SHA1();
    digest.add(input);
    return new Uint8List.fromList(digest.close());
  }
  
  /**
   * Calculates the RIPEMD-160 hash of the SHA-256 hash of the input.
   * This is used to convert an ECDSA public key to a Bitcoin address.
   */
  static Uint8List sha256hash160(Uint8List input) {
    return ripemd160Digest(singleDigest(input));
  }
  
  static Uint8List stringToUTF8(String string) {
    return new Uint8List.fromList(new Utf8Encoder().convert(string));
  }
  
  static String UTF8ToString(Uint8List bytes) {
    return new Utf8Decoder().convert(bytes);
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
    hex = hex.replaceAll(" ", "");
    hex = hex.toUpperCase();
    if(hex.length % 2 != 0) {
      hex = "0" + hex;
    }
    List<int> result = new List();
    while(hex.length > 0) {
      String byte = hex.substring(0, 2);
      hex = hex.substring(2, hex.length);
      
      int value = (_BYTE_ALPHABET.indexOf(byte[0]) << 4) //= byte[0] * 16 
          + _BYTE_ALPHABET.indexOf(byte[1]);
      result.add(value);
    }
    return new Uint8List.fromList(result);
  }
  
  static Uint8List reverseBytes(Uint8List bytes) {
    int length = bytes.length;
    Uint8List result = new Uint8List(length);
    for(int i = 0 ; i < length ; i++)
      result[i] = bytes[length - 1 - i];
    return result;
  }
  

  /** The string that prefixes all text messages signed using Bitcoin keys. */
  static final String BITCOIN_SIGNED_MESSAGE_HEADER = "Bitcoin Signed Message:\n";
  static final Uint8List BITCOIN_SIGNED_MESSAGE_HEADER_BYTES = new Uint8List.fromList(new Utf8Encoder().convert(BITCOIN_SIGNED_MESSAGE_HEADER));

  /**
   * <p>Given a textual message, returns a byte buffer formatted as follows:</p>
   *
   * <tt><p>[24] "Bitcoin Signed Message:\n" [message.length as a varint] message</p></tt>
   */
  static Uint8List formatMessageForSigning(String message) {
    List<int> result = new List<int>();
    result.add(BITCOIN_SIGNED_MESSAGE_HEADER_BYTES.length);
    result.addAll(BITCOIN_SIGNED_MESSAGE_HEADER_BYTES);
    Uint8List messageBytes = new Uint8List.fromList(new Utf8Encoder().convert(message));
    VarInt size = new VarInt(messageBytes.length);
    result.addAll(size.serialize());
    result.addAll(messageBytes);
    return new Uint8List.fromList(result);
  }
  
  /**
   * Mimics Java's System.arraycopy() method.
   * 
   * Uint8List.replaceRange doesn't work.
   */
  static void arrayCopy(Uint8List src, int srcPos, Uint8List dest, int destPos, [int length]) {
    length = length != null ? length : src.length;
    if(srcPos + length > src.length || destPos + length > dest.length)
      throw new ArgumentError("Invalid arguments: will cause overflow");
    for(int i = 0 ; i < length ; i++)
      dest[destPos + i] = src[srcPos + i];
  }
  
  /**
   * Compare two lists, returns true if lists contain the same elements.
   * 
   * "==" operator is used to compare the elements in the lists.
   */
  static bool equalLists(List list1, List list2) => new ListEquality(new DefaultEquality()).equals(list1, list2);
  
  /**
   * Generate a valid hashcode for the list.
   */
  static int listHashCode(List<int> list) => new ListEquality().hash(list);

  /**
   * The regular BigInteger.toByteArray() method isn't quite what we often need: it appends a
   * leading zero to indicate that the number is positive and may need padding.
   */
  static Uint8List bigIntegerToBytes(BigInteger b, int numBytes) {
    if (b == null) {
      return null;
    }
    Uint8List bytes = new Uint8List(numBytes);
    Uint8List biBytes = new Uint8List.fromList(b.toByteArray());
    int start = (biBytes.length == numBytes + 1) ? 1 : 0;
    int length = min(biBytes.length, numBytes);
    bytes.setRange(numBytes - length, numBytes, biBytes.sublist(start, start + length));
    return bytes;
  }
  
  /**
   * Converts the integer to a byte array in little endian. Ony positive integers allowed.
   */
  static Uint8List uintToBytesLE(int val, [int size = -1]) {
    if(val < 0) throw new Exception("Only positive values allowed.");
    List<int> result = new List();
    while(val > 0) {
      int mod = val & 0xff;
      val = val >> 8;
      result.add(mod);
    }
    if(size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
    while(result.length < size) result.add(0);
    return new Uint8List.fromList(result);
  }
  
  /**
   * Converts the integer to a byte array in big endian. Ony positive integers allowed.
   */
  static Uint8List uintToBytesBE(int val, [int size = -1]) {
    if(val < 0) throw new ArgumentError("Only positive values allowed.");
    List<int> result = new List();
    while(val > 0) {
      int mod = val & 0xff;
      val = val >> 8;
      result.insert(0, mod);
    }
    if(size >= 0 && result.length > size) throw new Exception("Value doesn't fit in given size.");
    while(result.length < size) result.insert(0, 0);
    return new Uint8List.fromList(result);
  }
  
  /**
   * Converts the [BigInteger] to a byte array in little endian.
   */
  static Uint8List uBigIntToBytesLE(BigInteger val, [int size = -1]) {
    List<int> bytes = val.toByteArray();
    if (bytes.length > size && size >= 0) {
      throw new Exception("Input too large to encode into a uint64");
    }
    bytes = new List.from(bytes.reversed);
    if (bytes.length < size) {
      while(bytes.length < size)
        bytes.add(0);
    }
    return new Uint8List.fromList(bytes);
  }
  
  /**
   * Converts the byte array to a [BigInteger] in little endian.
   */
  static BigInteger bytesToUBigIntLE(Uint8List bytes, [int size = -1]) {
    if(size < 0) size = bytes.length;
    return new BigInteger(Utils.reverseBytes(bytes.sublist(0, size)));
  }
  
  /**
   * Converts the big endian byte array to an unsigned integer.
   */
  static int bytesToUintBE(Uint8List bytes, [int size]) {
    if(size == null) size = bytes.length;
    int result = 0;
    for(int i = 0 ; i < size ; i++) {
      result += bytes[i] << (8 * (size - i - 1));
    }
    return result;
  }
  
  /**
   * Converts the little endian byte array to an unsigned integer.
   */
  static int bytesToUintLE(Uint8List bytes, [int size]) {
    if(size == null) size = bytes.length;
    int result = 0;
    for(int i = 0; i < size ; i++) {
      result += bytes[i] << (8 * i);
    }
    return result;
  }
  
  //TODO
  static Uint8List intTo2CBytes(int val, [int size]) {
    if(val < 0) {
      
    }
  }
  
  /**
   * Converts the BE endian two's complement encoded bytes to an integer.
   * 
   * Size in number of bytes, not bits;
   */
  //TODO not a quite satisfactory implementation
  static int bytesTo2CInt(Uint8List bytes, [int size]) {
    if(size == null) size = bytes.length;
    int result = bytesToUintBE(bytes, size);
    if(bytes[0] >= 0x40) { // number is negative
      result = result - pow(2, 8 * size);
    }
    return result;
  }
  
  /**
   * Encodes the [InternetAddress] to bytes.
   * 
   * [address] can be a IPv4 or IPv6 address.
   */
  // TODO change as soon as InternetAddress has it's own encoding method
  static Uint8List encodeInternetAddressAsIPv6(InternetAddress address) {
    if(address.type == InternetAddressType.IP_V6)
      return new Uint8List.fromList(Uri.parseIPv6Address(address.address));
    return new Uint8List(16)
      ..setRange(12, 16, Uri.parseIPv4Address(address.address))
      ..[10] = 0xFF
      ..[11] = 0xFF;
  }
  
  static String _zeroPad(String toPad, int size) {
    return new List.filled(size - toPad.length, "0").join() + toPad;
  }
  
  /**
   * Decode the bytes to an [InternetAddress].
   */
  static InternetAddress decodeInternetAddressAsIPv6(Uint8List bytes) {
    if(bytes.length != 16) throw new FormatException("illegal format");
    String address = "";
    for(int i = 0 ; i < 8 ; i++) {
      if(i != 0) address += ":";
      address += Utils.bytesToHex(bytes.sublist(i * 2, i * 2 + 2));
    }
    return new InternetAddress(address);
  }


  /**
   * MPI encoded numbers are produced by the OpenSSL BN_bn2mpi function. They consist of
   * a 4 byte big endian length field, followed by the stated number of bytes representing
   * the number in big endian format (with a sign bit).
   * @param hasLength can be set to false if the given array is missing the 4 byte length field
   */
  static BigInteger decodeMPI(Uint8List mpi, bool hasLength) {
    Uint8List buf;
    if (hasLength) {
      int length = bytesToUintBE(mpi, 4);
      buf = mpi.sublist(4);
    }
    else {
      buf = mpi;
    }
    if (buf.length == 0)
      return BigInteger.ZERO;
    bool isNegative = (buf[0] & 0x80) == 0x80;
    if (isNegative)
      buf[0] &= 0x7f;
    BigInteger result = new BigInteger(buf);
    return isNegative ? result.negate_op() : result;
  }
  
  /**
   * MPI encoded numbers are produced by the OpenSSL BN_bn2mpi function. They consist of
   * a 4 byte big endian length field, followed by the stated number of bytes representing
   * the number in big endian format (with a sign bit).
   * @param includeLength indicates whether the 4 byte length field should be included
   */
  static Uint8List encodeMPI(BigInteger value, bool includeLength) {
    if (value == 0) {
      if (!includeLength)
        return new Uint8List(0);
      else
        return new Uint8List(4);
    }
    bool isNegative = value < BigInteger.ZERO;
    if (isNegative)
      value = value.negate_op();
    Uint8List array = value.toByteArray();
    int length = array.length;
    if ((array[0] & 0x80) == 0x80)
      length++;
    if (includeLength) {
      Uint8List result = new Uint8List(length + 4);
      result.setRange(length - array.length + 3, length + 3, array);
      result.setRange(0, 4, uintToBytesBE(length, 4));
      if (isNegative)
        result[4] |= 0x80;
      return result;
    }
    else {
      Uint8List result;
      if (length != array.length) {
        result = new Uint8List(length);
        result.setRange(1, array.length + 1, array);
      }
      else {
        result = array;
      }
      if (isNegative)
        result[0] |= 0x80;
      return result;
    }
  }

  // The representation of nBits uses another home-brew encoding, as a way to represent a large
  // hash value in only 32 bits.
  static BigInteger decodeCompactBits(int compact) {
    int size = (compact >> 24) & 0xFF;
    Uint8List bytes = new Uint8List(4 + size);
    bytes[3] = size;
    if (size >= 1) bytes[4] = (compact >> 16) & 0xFF;
    if (size >= 2) bytes[5] = (compact >> 8)  & 0xFF;
    if (size >= 3) bytes[6] = (compact >> 0)  & 0xFF;
    return decodeMPI(bytes, true);
  }
  
  /**
   * Compute 32-bit logical shift right of a value. This emulates the Java >>> operator.
   */
  static int lsr(int n, int shift) {
    int shift5 = shift & 0x1f;
    int n32 = 0xffffffff & n;
    if (shift5 == 0)
      return n32;
    else
      return (n32 >> shift5) & ((0x7fffffff >> (shift5-1)));
  }
  
  /**
   * Checks if the given bit is set in data
   */
  static bool checkBitLE(Uint8List data, int index) {
    return (data[Utils.lsr(index, 3)] & _bitMask[7 & index]) != 0;
  }
  static final Uint8List _bitMask = new Uint8List.fromList([0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]);
  
  /**
   * Sets the given bit in data to one
   */
  static void setBitLE(Uint8List data, int index) {
    data[Utils.lsr(index, 3)] |= _bitMask[7 & index];
  }
}






