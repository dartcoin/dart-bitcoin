library dartcoin.test.wire.version_message;

import "dart:typed_data";

import "package:bignum/bignum.dart";
import "package:bytes/bytes.dart";
import "package:cryptoutils/cryptoutils.dart";

import "package:test/test.dart";

import "package:dartcoin/core.dart";
import "package:dartcoin/wire.dart";


void main() {
  group("wire.messages.VersionMessage", () {

    test("decode", () {

        VersionMessage ver = new VersionMessage.empty();
        ver.bitcoinDeserialize(new Reader(CryptoUtils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f0004000000"))
            , 0);
        expect(ver.relayBeforeFilter, isFalse);
        expect(ver.lastHeight, equals(1024));
        expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));

        ver.bitcoinDeserialize(new Reader(CryptoUtils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f00040000"))
            , 0);
        expect(ver.relayBeforeFilter, isTrue);
        expect(ver.lastHeight, equals(1024));
        expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));

        ver.bitcoinDeserialize(new Reader(CryptoUtils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f"))
            , 0);
        expect(ver.relayBeforeFilter, isTrue);
        expect(ver.lastHeight, equals(0));
        expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));

        ver.bitcoinDeserialize(new Reader(CryptoUtils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000"))
            , 0);
        expect(ver.relayBeforeFilter, isTrue);
        expect(ver.lastHeight, equals(0));
        expect(ver.subVer, equals(""));
    });

    test("bothways", () {
    //  BigInteger this.services,
    //  int this.time: 0,
    //  PeerAddress this.myAddress,
    //  PeerAddress this.theirAddress,
    //  int this.nonce: 0,
    //  String this.subVer,
    //  int this.lastHeight: 0,
    //  bool this.relayBeforeFilter: false,
    //
      var clientVersion = NetworkParameters.PROTOCOL_VERSION;
      var services = BigInteger.ONE;
      var time = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var myAddress = new PeerAddress.localhost(services: services, port: 8333);
      var theirAddress = new PeerAddress("192.168.3.3", port: 8333, services: services, time: time);
      var nonce = 12321;
      var subVer = VersionMessage.LIBRARY_SUBVER;
      var lastHeight = 12345;
      var relay = false;

      VersionMessage ver = new VersionMessage(
          clientVersion: clientVersion,
          services: services,
          time: time,
          myAddress: myAddress,
          theirAddress: theirAddress,
          nonce: nonce,
          subVer: subVer,
          lastHeight: lastHeight,
          relayBeforeFilter: relay);
      Uint8List bytes = ver.bitcoinSerializedBytes(clientVersion);
      VersionMessage newVer = new VersionMessage.empty();
      newVer.bitcoinDeserialize(new Reader(bytes), clientVersion);

      expect(newVer.clientVersion, equals(clientVersion));
      expect(newVer.services, equals(services));
      expect(newVer.time, equals(time));
      expect(newVer.myAddress.address, equals(myAddress.address));
      expect(newVer.theirAddress.address, equals(theirAddress.address));
      expect(newVer.nonce, equals(nonce));
      expect(newVer.subVer, equals(subVer));
      expect(newVer.lastHeight, equals(lastHeight));
      expect(newVer.relayBeforeFilter, equals(relay));

    });
  });
}









