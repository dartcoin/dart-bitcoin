library dartcoin.test.wire.version_message;


import "package:unittest/unittest.dart";

import "package:dartcoin/core/core.dart";

import "package:bignum/bignum.dart";

import "dart:io";
import "dart:typed_data";


void _generateVersionMessage(Uint8List payload) {
  
}

// Test that we can decode version messages which miss data which some old nodes may not include
void _testDecode() {
    NetworkParameters params = NetworkParameters.UNIT_TEST;
    
    VersionMessage ver = new Message.fromPayload("version", Utils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f0004000000")
        , params: params);
    expect(ver.relayBeforeFilter, isFalse);
    expect(ver.lastHeight, equals(1024));
    expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));
    
    ver = new Message.fromPayload("version", Utils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f00040000")
        , params: params);
    expect(ver.relayBeforeFilter, isTrue);
    expect(ver.lastHeight, equals(1024));
    expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));
    
    ver = new Message.fromPayload("version", Utils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000172f426974436f696e4a3a302e372d534e415053484f542f")
        , params: params);
    expect(ver.relayBeforeFilter, isTrue);
    expect(ver.lastHeight, equals(0));
    expect(ver.subVer, equals("/BitCoinJ:0.7-SNAPSHOT/"));
    
    ver = new Message.fromPayload("version", Utils.hexToBytes("71110100000000000000000048e5e95000000000000000000000000000000000000000000000ffff7f000001479d000000000000000000000000000000000000ffff7f000001479d0000000000000000")
        , params: params);
    expect(ver.relayBeforeFilter, isTrue);
    expect(ver.lastHeight, equals(0));
    expect(ver.subVer, equals(""));
}

void _testBothWays() {
  NetworkParameters params = NetworkParameters.UNIT_TEST;
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
  var myAddress = new PeerAddress.localhost(params: params, services: services);
  var theirAddress = new PeerAddress(new InternetAddress("192.168.3.3"), port: 8333, protocolVersion: clientVersion, params: params, services: services, time: time);
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
  Uint8List bytes = ver.serialize();
  VersionMessage newVer = new VersionMessage.deserialize(bytes, params: params, protocolVersion: clientVersion);
  
  expect(newVer.clientVersion, equals(clientVersion));
  expect(newVer.services, equals(services));
  expect(newVer.time, equals(time));
  expect(newVer.myAddress.address.rawAddress.sublist(12, 16), equals(myAddress.address.rawAddress));
  expect(newVer.theirAddress.address.rawAddress.sublist(12, 16), equals(theirAddress.address.rawAddress));
  expect(newVer.nonce, equals(nonce));
  expect(newVer.subVer, equals(subVer));
  expect(newVer.lastHeight, equals(lastHeight));
  expect(newVer.relayBeforeFilter, equals(relay));
  
}

void main() {
  group("wire.messages.VersionMessage", () {
    test("decode", () => _testDecode());
    test("bothways", () => _testBothWays());
  });
}









