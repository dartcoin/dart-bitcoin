library bitcoin.test.core.address;

import "package:test/test.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:bitcoin/core.dart";

import "dart:typed_data";

final NetworkParameters _testParams = NetworkParameters.TEST_NET;
final NetworkParameters _mainParams = NetworkParameters.MAIN_NET;

void main() {
  group("core.Address", () {
    test("stringification", () {
      // Test a testnet address.
      Address a = new Address.fromHash160(
          CryptoUtils.hexToBytes("fda79a24e50ff70ff42f7d89585da5bd19d9e5cc"),
          _testParams.addressHeader);
      expect(a.toString(), equals("n4eA2nbYqErp7H6jebchxAN59DmNpksexv"));
      expect(a.address, equals("n4eA2nbYqErp7H6jebchxAN59DmNpksexv"));
      expect(a.isP2SHAddress(_testParams), isFalse);

      Address b = new Address.fromHash160(
          CryptoUtils.hexToBytes("4a22c3c4cbb31e4d03b15550636762bda0baf85a"),
          _mainParams.addressHeader);
      expect(b.toString(), equals("17kzeh4N8g49GFvdDzSf8PjaPfyoD1MndL"));
      expect(b.address, equals("17kzeh4N8g49GFvdDzSf8PjaPfyoD1MndL"));
      expect(b.isP2SHAddress(_mainParams), isFalse);
    });

    test("decoding", () {
      Address a = new Address("n4eA2nbYqErp7H6jebchxAN59DmNpksexv");
      expect(CryptoUtils.bytesToHex(a.hash160.asBytes()),
          equals("fda79a24e50ff70ff42f7d89585da5bd19d9e5cc"));

      Address b = new Address("17kzeh4N8g49GFvdDzSf8PjaPfyoD1MndL");
      expect(CryptoUtils.bytesToHex(b.hash160.asBytes()),
          equals("4a22c3c4cbb31e4d03b15550636762bda0baf85a"));
    });

    test("errorPaths", () {
      // Check what happens if we try and decode garbage.
      try {
        new Address("this is not a valid address!");
        fail("should not work");
      } on FormatException {
        // success
      } catch (e) {
        fail("wrong exception: $e");
      }

      // Check the empty case.
      try {
        new Address("");
        fail("should not work");
      } on FormatException {
        // success
      } catch (e) {
        fail("wrong exception: $e");
      }
    });

    test("getNetwork", () {
      NetworkParameters params = new Address("17kzeh4N8g49GFvdDzSf8PjaPfyoD1MndL").findNetwork();
      expect(params.id, _mainParams.id);
      params = new Address("n4eA2nbYqErp7H6jebchxAN59DmNpksexv").findNetwork();
      expect(params.id, _testParams.id);
    });

    test("p2shAddress", () {
      // Test that we can construct P2SH addresses
      Address mainNetP2SHAddress = new Address("35b9vsyH1KoFT5a5KtrKusaCcPLkiSo1tU");
      expect(mainNetP2SHAddress.version, equals(_mainParams.p2shHeader));
      expect(mainNetP2SHAddress.isP2SHAddress(_mainParams), isTrue);
      Address testNetP2SHAddress = new Address("2MuVSxtfivPKJe93EC1Tb9UhJtGhsoWEHCe");
      expect(testNetP2SHAddress.version, equals(_testParams.p2shHeader));
      expect(testNetP2SHAddress.isP2SHAddress(_testParams), isTrue);

      // Test that we can determine what network a P2SH address belongs to
      NetworkParameters mainNetParams =
          new Address("35b9vsyH1KoFT5a5KtrKusaCcPLkiSo1tU").findNetwork();
      expect(mainNetParams.id, _mainParams.id);
      NetworkParameters testNetParams =
          new Address("2MuVSxtfivPKJe93EC1Tb9UhJtGhsoWEHCe").findNetwork();
      expect(testNetParams.id, _testParams.id);

      // Test that we can convert them from hashes
      Uint8List hex = CryptoUtils.hexToBytes("2ac4b0b501117cc8119c5797b519538d4942e90e");
      Address a = new Address.p2sh(hex, _mainParams);
      expect(a.toString(), equals("35b9vsyH1KoFT5a5KtrKusaCcPLkiSo1tU"));
      Address b = new Address.p2sh(
          CryptoUtils.hexToBytes("18a0e827269b5211eb51a4af1b2fa69333efa722"), _testParams);
      expect(b.toString(), equals("2MuVSxtfivPKJe93EC1Tb9UhJtGhsoWEHCe"));
    });
  });
}
