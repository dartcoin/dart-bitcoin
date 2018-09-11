import 'dart:math';

import 'package:bitcoin/crypto/hdkey.dart';
import 'package:eth_wallet_dart/src/bip39/mnemonic.dart';
import 'package:eth_wallet_dart/src/bip39/utils.dart';
import 'package:test/test.dart';
import 'package:web3dart/conversions.dart';

import 'package:web3dart/src/utils/crypto.dart';
import 'package:web3dart/src/utils/dartrandom.dart';


import 'package:web3dart/web3dart.dart';

void main() {
  test("Mnemonic List Word Loading Test", () {
    var mnemonicWordList = MnemonicUtils.populateWordList();
    expect(mnemonicWordList.isNotEmpty, true);
  });

  test("Generate Mnemonic List", () {
    Random random = new Random.secure();
    var mnemonic =
    MnemonicUtils.generateMnemonic(new DartRandom(random).nextBytes(32));

    expect(mnemonic.isNotEmpty, true);
  });

  test(
      "Generate Master Seed From Known Mnemonic List Compare With Pre-Known Seed",
          () {
        var seed = MnemonicUtils.generateMasterSeed(
            "uniform snow notice device spring universe source pulp road meadow slow kind hurry silly crowd",
            "");

        var masterSeedHex = bytesToHex(seed);

        expect(masterSeedHex,
            "bada2b2d32593027a42e37bc42196faec8d7a7ecea7ecddbf9cf5ef4bf2e18073bad102048e1a4ae30d0f767822377d13bde1e05f0300f3f7c93e62e279f257e");
      });

  test("Generate Master Seed With Passphrase", () {
    var seed = MnemonicUtils.generateMasterSeed(
        "cram vacuum rebuild assault cruise fit dinner asthma crew social unique keen turtle display autumn",
        "passw0rd");

    var masterSeedHex = bytesToHex(seed);

    expect(masterSeedHex,
        "004c3148612fb6329be0000971df301f6fbe002a0099f31c043b4b2678ce02aec806f470052b7b1822032bce2871fc3b989bebd2cfcf54a5687137b25753f533");
  });

//

  test("Child Private Key Hardened Derivation Test", () {
    var rootSeed = getRootSeed(hexToBytes(
        "bada2b2d32593027a42e37bc42196faec8d7a7ecea7ecddbf9cf5ef4bf2e18073bad102048e1a4ae30d0f767822377d13bde1e05f0300f3f7c93e62e279f257e"));

//    print("Root Seed: ${ bytesToHex(rootSeed) }");

    var childPrivateKeyHardened = CKDprivHardened(
      rootSeed,
      0,
    )[0];

    var childChainCode = CKDprivHardened(
      rootSeed,
      0,
    )[1];

    var cprivkHardHex = bytesToHex(childPrivateKeyHardened);
    var publicKey = Credentials
        .fromPrivateKeyHex(cprivkHardHex)
        .publicKey
        .toRadixString(16);
    var address = Credentials.fromPrivateKeyHex(cprivkHardHex).address.hex;
    var chainCodeHex = bytesToHex(childChainCode);

//    print("Private Key: ${cprivkHardHex} \nPublic Key: ${publicKey} \nAddress: ${address} \nChainCode: ${chainCodeHex}");

    expect(address, "0xdc04c29a3ce6c09edf7b3b38ae3f39413148a8ba");
  });

  test("Child Private Key Non Hardened Derivation Test", () {
    var rootSeed = getRootSeed(hexToBytes(
        "271ef7ac032bb8a313e2d3339ac6bc308bd984de98c6095767b7496a517708d6ade22355e0415e771a732e3db45fe3e15da7ad7550cda08787b3902a1d092e15"));

//    print("Root Seed: ${ bytesToHex(rootSeed) }");

    var childPrivateKeyHardened = CKDprivNonHardened(
      rootSeed,
      0,
    )[0];

    var childChainCode = CKDprivNonHardened(
      rootSeed,
      0,
    )[1];

    var cprivkHardHex = bytesToHex(childPrivateKeyHardened);
    var publicKey = Credentials
        .fromPrivateKeyHex(cprivkHardHex)
        .publicKey
        .toRadixString(16);
    var address = Credentials.fromPrivateKeyHex(cprivkHardHex).address.hex;
    var chainCodeHex = bytesToHex(childChainCode);

//    print(
//        "Private Key: ${cprivkHardHex} \nPublic Key: ${publicKey} \nAddress: ${address} \nChainCode: ${chainCodeHex}");

    expect(address, "0x81e873d1be33d0e4b044d5c0ebeb27834ddea944");
//
  });

  test("Public key compression", () {
    var pubk = "04" +
        "a563d19906ea9208d6e6879cab449646571420f7ce2236890fdd71f73eadc75e64c540ad3ddf64b379d7a56f4baa16a83a7957db2c6f4243ada01a45bef39852";

    var pubKeyCompressed = (getCompressedPubKey((pubk)));

    expect(pubKeyCompressed,
        "02a563d19906ea9208d6e6879cab449646571420f7ce2236890fdd71f73eadc75e");
  });




  test("Ethereum standard HD Wallet Derivation", () {

    String publicKeyParent = "04"+ bytesToHex(privateKeyToPublic(hexToBytes("8fbefa83ad9cbb8ba778494569589baf53d6bc0ed01b19e0e1f8d17e91d6b80c")))   ;

    print("🏁🏁🏁 PubKey: [${publicKeyParent.length}] ${publicKeyParent}");

    var rootSeed = getRootSeed(hexToBytes(
        "df1bcf7895eb1d93df7ba805063648f799cc8d4965072ae2e0d6f1028490bb81c3ab434357938fe6db8306561d566b883b21b5bd78437897b8dc17de6219c3f5"));

    EthereumStandardHDWalletPath((rootSeed));




  });





























}