library dartcoin.test.crypto.key_crypter_scrypt;

import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "dart:typed_data";
import "dart:math";

import "package:cipher/cipher.dart";
import "package:uuid/uuid.dart";



// Nonsense bytes for encryption test.
final Uint8List _TEST_BYTES1 = new Uint8List.fromList([0, -101, 2, 103, -4, 105, 6, 107, 8, -109, 10, 111, -12, 113, 14, -115, 16, 117, -18, 119, 20, 121, 22, 123, -24, 125, 26, 127, -28, 29, -30, 31]);

final String _PASSWORD1 = "aTestPassword";
final String _PASSWORD2 = "0123456789";

final String _WRONG_PASSWORD = "thisIsTheWrongPassword";

ScryptParameters _scryptParameters;

void _setUp() {
  Uint8List salt = new Uint8List(KeyCrypterScrypt.SALT_LENGTH);
  Random r = new Random();
  for(int i = 0 ; i < KeyCrypterScrypt.SALT_LENGTH ; i++) salt[i] = r.nextInt(256); 
  _scryptParameters = KeyCrypterScrypt.scryptParamsWithSalt(salt);
}


void _testKeyCrypterGood1() {
  KeyCrypterScrypt keyCrypter = new KeyCrypterScrypt(_scryptParameters);

  // Encrypt.
  EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(_TEST_BYTES1, keyCrypter.deriveKey(_PASSWORD1));
  expect(encryptedPrivateKey, isNotNull);

  // Decrypt.
  Uint8List reborn = keyCrypter.decrypt(encryptedPrivateKey, keyCrypter.deriveKey(_PASSWORD1));
  print("Original: " + Utils.bytesToHex(_TEST_BYTES1));
  print("Reborn  : " + Utils.bytesToHex(reborn));
  expect(Utils.bytesToHex(reborn), equals(Utils.bytesToHex(_TEST_BYTES1)));
}

/**
 * Test with random plain text strings and random passwords.
 * UUIDs are used and hence will only cover hex characters (and the separator hyphen).
 * @throws KeyCrypterException
 * @throws UnsupportedEncodingException
 */

void _testKeyCrypterGood2() {
  KeyCrypterScrypt keyCrypter = new KeyCrypterScrypt(_scryptParameters);

  print("EncrypterDecrypterTest: Trying random UUIDs for plainText and passwords :");
  int numberOfTests = 16;
  Uuid uuid = new Uuid();
  for (int i = 0; i < numberOfTests; i++) {
    // Create a UUID as the plaintext and use another for the password.
    String plainText = uuid.v4();
    String password = uuid.v4();

    EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(Utils.stringToUTF8(plainText), keyCrypter.deriveKey(password));

    expect(encryptedPrivateKey, isNotNull);

    Uint8List reconstructedPlainBytes = keyCrypter.decrypt(encryptedPrivateKey,keyCrypter.deriveKey(password));
    expect(Utils.bytesToHex(reconstructedPlainBytes), equals(Utils.bytesToHex(Utils.stringToUTF8(plainText))));
    print('.');
  }
  print(" Done.");
}


void _testKeyCrypterWrongPassword() {
  KeyCrypterScrypt keyCrypter = new KeyCrypterScrypt(_scryptParameters);

  // create a longer encryption string
  StringBuffer stringBuffer = new StringBuffer();
  for (int i = 0; i < 100; i++) {
    stringBuffer..write(i)..write(" ")..write("The quick brown fox");
  }

  EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(Utils.stringToUTF8(stringBuffer.toString()), keyCrypter.deriveKey(_PASSWORD2));
  expect(encryptedPrivateKey, isNotNull);

  
  expect(() => keyCrypter.decrypt(encryptedPrivateKey, keyCrypter.deriveKey(_WRONG_PASSWORD)), throws);
}


void _testEncryptDecryptBytes1() {
    KeyCrypterScrypt keyCrypter = new KeyCrypterScrypt(_scryptParameters);

    // Encrypt bytes.
    EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(_TEST_BYTES1, keyCrypter.deriveKey(_PASSWORD1));
    expect(encryptedPrivateKey, isNotNull);
    print("\nEncrypterDecrypterTest: cipherBytes = \nlength = ${encryptedPrivateKey.encryptedKey.length}\n---------------\n${Utils.bytesToHex(encryptedPrivateKey.encryptedKey)}\n---------------\n");

    Uint8List rebornPlainBytes = keyCrypter.decrypt(encryptedPrivateKey, keyCrypter.deriveKey(_PASSWORD1));

    print("Original: " + Utils.bytesToHex(_TEST_BYTES1));
    print("Reborn1 : " + Utils.bytesToHex(rebornPlainBytes));
    expect(Utils.bytesToHex(rebornPlainBytes), equals(Utils.bytesToHex(_TEST_BYTES1)));
}


void _testEncryptDecryptBytes2() {
    KeyCrypterScrypt keyCrypter = new KeyCrypterScrypt(_scryptParameters);

    // Encrypt random bytes of various lengths up to length 50.
    Random r = new Random();

    for (int i = 0; i < 50; i++) {
        Uint8List plainBytes = new Uint8List(i);
        for(int j = 0 ; j < i ; j++) plainBytes[j] = r.nextInt(256);

        EncryptedPrivateKey encryptedPrivateKey = keyCrypter.encrypt(plainBytes, keyCrypter.deriveKey(_PASSWORD1));
        expect(encryptedPrivateKey, isNotNull);
        //log.debug("\nEncrypterDecrypterTest: cipherBytes = \nlength = " + cipherBytes.length + "\n---------------\n" + Utils.bytesToHexString(cipherBytes) + "\n---------------\n");

        Uint8List rebornPlainBytes = keyCrypter.decrypt(encryptedPrivateKey, keyCrypter.deriveKey(_PASSWORD1));

        print("Original: ($i) " + Utils.bytesToHex(plainBytes));
        print("Reborn1 : ($i) " + Utils.bytesToHex(rebornPlainBytes));
        expect(Utils.bytesToHex(rebornPlainBytes), equals(Utils.bytesToHex(plainBytes)));
    }
}


void main() {
  group("crypto.KeyCrypterScrypt", () {
    setUp(() => _setUp());
    test("KeyCrypterGood1", () => _testKeyCrypterGood1());
    test("KeyCrypterGood2", () => _testKeyCrypterGood2());
    test("KeyCrypterWrongPasswd", () => _testKeyCrypterWrongPassword());
    test("EncryptDecryptBytes1", () => _testEncryptDecryptBytes1());
    test("EncryptDecryptBytes2", () => _testEncryptDecryptBytes2());
  });
}







