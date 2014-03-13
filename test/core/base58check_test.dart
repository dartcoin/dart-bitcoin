library dartcoin.test.core.base58check;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "package:bignum/bignum.dart";
import "dart:typed_data";
import "dart:convert";

// bitcoinj

void _testEncode() {
    Uint8List testbytes = new Uint8List.fromList(new Utf8Encoder().convert("Hello World"));
    expect(Base58Check.encode(testbytes), equals("JxF12TrwUP45BMd"));
    
    BigInteger bi = new BigInteger(3471844090);
    expect(Base58Check.encode(new Uint8List.fromList(bi.toByteArray())), equals("16Ho7Hs"));
    
    Uint8List zeroBytes1 = new Uint8List(1);
    expect(Base58Check.encode(zeroBytes1), equals("1"));
    
    Uint8List zeroBytes7 = new Uint8List(7);
    expect(Base58Check.encode(zeroBytes7), equals("1111111"));

    // test empty encode
    expect(Base58Check.encode(new Uint8List(0)), equals(""));
}


void _testDecode() {
    Uint8List testbytes = new Uint8List.fromList(new Utf8Encoder().convert("Hello World"));
    Uint8List actualbytes = Base58Check.decode("JxF12TrwUP45BMd");
    expect(actualbytes, equals(testbytes));

    expect(Base58Check.decode("1"), equals(new Uint8List(1)));
    expect(Base58Check.decode("1111"), equals(new Uint8List(4)));
    
    expect(() => Base58Check.decode("This isn't valid base58"), throwsFormatException);

    expect(() => Base58Check.decodeChecked("4stwEBjT6FYyVV"), returnsNormally);

    // Checksum should fail.
    expect(() => Base58Check.decodeChecked("4stwEBjT6FYyVW"), throwsFormatException);

    // Input is too short.
    expect(() => Base58Check.decodeChecked("4s"), throwsFormatException);

    // Test decode of empty String.
    expect(Base58Check.decode("").length, equals(0));

    // Now check we can correctly decode the case where the high bit of the first byte is not zero, so BigInteger
    // sign extends. Fix for a bug that stopped us parsing keys exported using sipas patch.
    expect(() => Base58Check.decodeChecked("93VYUMzRG9DdbRP72uQXjaWibbQwygnvaCu9DumcqDjGybD864T"), returnsNormally);
}

main() {
  group("core.Base58Check", () {
    test("encode", () => _testEncode());
    test("decode", () => _testDecode());
  });
}
  
  
  
  